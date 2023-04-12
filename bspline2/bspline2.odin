package bspline2
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

import "core:fmt"
import la "core:math/linalg"
import "core:math"
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
lerp :: la.lerp
lerp_inv :: la.unlerp
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Vector2 :: [2]f32

/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
BSpline_2D :: struct {
	points:    []Vector2,
	knots:     []f32,
	degree:    int,
	_eval_buf: []Vector2,
}
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//Creates a B-spline of the given degree, from a set of points and a knot vector
bspline_2d :: proc(points: []Vector2, knots: []f32, degree: int = 3) -> BSpline_2D {
	bsp: BSpline_2D = {}
	bsp.points = points
	bsp.knots = knots
	bsp.degree = degree
	knot_count := len(points) + 1 + degree
	if knot_count != len(knots) {
		fmt.eprintln(
			"The knots array has to be of length (degree+point_count+1). Got an array of %d knots, expected %d",
			len(knots),
			knot_count,
		)
	}
	order := degree + 1
	bsp._eval_buf = make([]Vector2, order) //todo destruct
	return bsp
}
//Creates a uniform B-spline of the given degree, automatically configuring the knot vector to be uniform
bspline_2d_uniform :: proc(points: []Vector2, degree: int = 3, open: bool = false) -> BSpline_2D {
	assert(degree >= 1)
	bsp: BSpline_2D = {}
	bsp.points = points
	bsp.knots = generate_uniform_knots(degree, len(points), open) //todo cleanup memory
	bsp.degree = degree
	order := degree + 1
	bsp._eval_buf = make([]Vector2, order) //todo cleanup memory
	return bsp
}
generate_uniform_knots :: proc(degree: int, pt_len: int, open: bool) -> []f32 {
	k_count := degree + pt_len + 1
	knots := make([]f32, k_count)
	// open:		0 0[0 1 2 3 4]4 4
	// closed:	   [0 1 2 3 4 5 6 7 8]
	for i := 0; i < k_count; i += 1 {
		knots[i] = !open ? f32(i) : math.clamp(f32(i - degree), 0., f32(k_count - 2 * degree - 1))
	}
	return knots
}
//The Order of this curve (degree+1)
order :: proc(spline: ^BSpline_2D) -> int {
	return spline.degree + 1
}
//The number of control points in the B-spline hull
point_count :: proc(spline: ^BSpline_2D) -> int {
	return len(spline.points)
}
//The number of knots in the B-spline parameter space
knot_count :: proc(spline: ^BSpline_2D) -> int {
	return len(spline.knots)
}
//The number of knots in the internal parameter space
internal_knot_count :: proc(spline: ^BSpline_2D) -> int {
	return len(spline.knots) - spline.degree * 2
}
//The number of curve segments. Note: some of these curve segments may have a length of 0 depending on knot multiplicity
segment_count :: proc(spline: ^BSpline_2D) -> int {
	return internal_knot_count(spline) - 1
}
//The first knot index of the internal parameter space
internal_knot_index_start :: proc(spline: ^BSpline_2D) -> int {
	return spline.degree
}
//The last knot index of the internal parameter space
internal_knot_index_end :: proc(spline: ^BSpline_2D) -> int {
	return len(spline.knots) - spline.degree - 1
}
//The parameter space knot value at the start of the internal parameter space
internal_knot_value_start :: proc(spline: ^BSpline_2D) -> f32 {
	return spline.knots[internal_knot_index_start(spline)]
}
//The parameter space knot value at the end of the internal parameter space
internal_knot_value_end :: proc(spline: ^BSpline_2D) -> f32 {
	return spline.knots[internal_knot_index_end(spline)]
}
//Returns the parameter space knot u-value, given a t-value along the whole spline
get_knot_value_at :: proc(spline: ^BSpline_2D, t: f32) -> f32 {
	return math.lerp(
		spline.knots[spline.degree],
		spline.knots[len(spline.knots) - spline.degree - 1],
		t,
	)
}
//Returns whether or not this B-spline is open, which means it will pass through its endpoints.
is_open :: proc(spline: ^BSpline_2D) -> bool {
	kc := len(spline.knots)
	for i := 0; i < spline.degree; i += 1 {
		if spline.knots[i] != spline.knots[i + 1] {
			return false
		}
		if spline.knots[kc - 1 - i] != spline.knots[kc - i - 2] {
			return false
		}

	}
	return true
}
//Returns the derivative of this B-spline, which is another B-spline
differentiate :: proc(spline: ^BSpline_2D) -> BSpline_2D {
	d_knots := make([]f32, len(spline.knots))
	for i := 0; i < len(d_knots); i += 1 {
		d_knots[i] = spline.knots[i + 1]
	}
	d_pts := make([]Vector2, len(spline.points) - 1)
	using spline
	for i := 0; i < len(d_pts); i += 1 {
		n := points[i + 1] - points[i]
		den := knots[i + degree + 1] - knots[i + 1]
		scale := den == 0. ? 0. : f32(degree) / den
		d_pts[i] = n * scale
	}
	return bspline_2d(d_pts, d_knots, degree - 1)
}
// based on https://en.wikipedia.org/wiki/De_Boor%27s_algorithm
//Returns the point at the given De-Boor recursion depth, knot interval and parameter space u-value
//@param k: The index of the knot interval our u-value is inside
//@parm u: A value in parameter space. Note: this value has to be within the internal knot interval
eval_de_boor :: proc(spline: ^BSpline_2D, k: int, u: f32) -> Vector2 {
	using spline
	if _eval_buf == nil || len(_eval_buf) != degree + 1 {
		_eval_buf = make([]Vector2, degree + 1)
	}
	//pre-populate
	for i := 0; i < degree + 1; i += 1 {
		_eval_buf[i] = points[i + k - degree]
	}
	//recurse layers
	for r := 1; r < degree + 1; r += 1 {
		for j := degree; j > r - 1; j -= 1 {
			alpha := lerp_inv(knots[j + k - degree], knots[j + 1 + k - r], u)
			_eval_buf[j] = math.lerp(_eval_buf[j - 1], _eval_buf[j], alpha)
		}
	}
	return _eval_buf[degree]
}
//Returns the point at the given t-value of a specific B-spline segment, by index
//t:along segment length
get_seg_point :: proc(spline: ^BSpline_2D, seg: int, t: f32) -> Vector2 {
	using spline
	if seg < 0 || seg >= segment_count(spline) {
		fmt.println(
			"B-Spline segment index %d is out of range. Valid indices: 0 to %d",
			seg,
			segment_count(spline) - 1,
		)
		panic("B-Spline segment index is out of range")
	}
	k_min := knots[degree + seg]
	k_max := knots[degree + seg + 1]
	u := math.lerp(k_min, k_max, t)
	return eval_de_boor(spline, degree + seg, u)
}
//Returns the point at the given t-value in the spline
get_point :: proc(spline: ^BSpline_2D, t: f32) -> Vector2 {
	using spline
	u := get_knot_value_at(spline, t)
	return get_point_by_knot_value(spline, u)
}
//Returns the point at the given knot by index
get_point_by_index :: proc(spline: ^BSpline_2D, i: int) -> Vector2 {
	using spline
	i := i
	k_ref := math.clamp(internal_knot_index_start(spline), internal_knot_index_end(spline) - 1, i)
	return eval_de_boor(spline, k_ref, knots[i])
}
//Returns the point at the given prameter space u-value of the spline
get_point_by_knot_value :: proc(spline: ^BSpline_2D, u: f32) -> Vector2 {
	using spline
	ike := internal_knot_index_end(spline)
	i := 0
	if u >= knots[ike] {
		i = ike - 1 // to handle the t = 1 special case
	} else {
		for j := 0; j < len(knots); j += 1 {
			if knots[j] <= u && u < knots[j + 1] {
				i = j
				break
			}
		}
	}
	return eval_de_boor(spline, i, u)
}
//Cox–de Boor recursion
// p = the point to get the basis curve for
// k = depth of recursion, where 0 = base knots. generally you start with k = Order
// u = knot value
eval_basis :: proc(spline: ^BSpline_2D, p: int, k: int, u: f32) -> f32 {
	using spline
	k := k - 1
	if k == 0 {
		if p == len(knots) - 2 { 	// NOTE(freya): todo: verify this, I just hacked it in, seems sus af
			return knots[p] <= u && u < knots[p + 1] ? 1 : 0
		}
		return knots[p] <= u && u < knots[p + 1] ? 1 : 0
	}
	return(
		eval_basis_w(spline, p, k, u) * eval_basis(spline, p, k, u) +
		(1. - eval_basis_w(spline, p + 1, k, u)) * eval_basis(spline, p + 1, k, u) \
	)
}
eval_basis_w :: proc(spline: ^BSpline_2D, i: int, k: int, t: f32) -> f32 {
	using spline
	den := knots[i + k] - knots[i]
	if den == 0 {return 0}
	return (t - knots[i]) / den
}
//Returns the basis curve of a given point (by index), at the given parameter space u-value
//pt: The point to get the basis curve of
//u: A value in parameter space. Note: this value has to be within the internal knot interval
get_point_weight_at_knot_value :: proc(spline: ^BSpline_2D, point: int, u: f32) -> f32 {
	return eval_basis(spline, point, order(spline), u)
}
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
