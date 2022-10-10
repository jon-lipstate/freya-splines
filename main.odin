package freya
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

import "core:fmt"
import la "core:math/linalg"
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
lerp :: la.lerp
lerp_inv :: la.unlerp
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Vector2 :: la.Vector2f32
v2_lerp :: proc(a: Vector2, b: Vector2, t: f32) -> Vector2 {
	result: Vector2 = {}
	result.x = la.lerp(a.x, b.x, t)
	result.y = lerp(a.y, b.y, t)
	return result
}

remap :: proc(
	in_min: f32,
	in_max: f32,
	out_min: f32,
	out_max: f32,
	in_val: f32,
) -> (
	out_val: f32,
) {
	t := lerp_inv(in_min, in_max, in_val)
	out_val = lerp(out_min, out_max, t)
	return out_val
}
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Bezier_2D :: struct {
	control_points: []Vector2,
	_pt_eval_buf:   []Vector2,
}
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

bezier_2d :: proc(control_points: []Vector2) -> Bezier_2D {
	val: Bezier_2D = {}
	if control_points == nil || len(control_points) < 2 {
		fmt.println("Bézier curves require at least two points")
	}
	val._pt_eval_buf = make([]Vector2, len(control_points) - 1) // todo check how to clean up
	val.control_points = control_points
	return val
}
bezier_2d_start_pt :: proc(bezier_2d: ^Bezier_2D) -> Vector2 {
	return bezier_2d.control_points[0]
}
bezier_2d_end_pt :: proc(bezier_2d: ^Bezier_2D) -> Vector2 {
	last_index := len(bezier_2d.control_points) - 1
	return bezier_2d.control_points[last_index]
}

bezier_2d_count :: proc(bezier_2d: ^Bezier_2D) -> uint {
	return len(bezier_2d.control_points)
}

bezier_2d_degree :: proc(bezier_2d: ^Bezier_2D) -> uint {
	return len(bezier_2d.control_points) - 1
}
bezier_2d_get_point :: proc(bezier_2d: ^Bezier_2D, t: f32) -> Vector2 {
	n := len(bezier_2d.control_points) - 1
	for i := 0; i < n; i += 1 {
		pi := bezier_2d.control_points[i]
		pi1 := bezier_2d.control_points[i + 1]
		bezier_2d._pt_eval_buf[i] = lerp(pi, pi1, t)
	}
	for {
		n -= 1
		for i := 0; i < n; i += 1 {
			pi := bezier_2d._pt_eval_buf[i]
			pi1 := bezier_2d._pt_eval_buf[i + 1]
			bezier_2d._pt_eval_buf[i] = lerp(pi, pi1, t)
		}
		if n <= 1 {break}
	}
	v := bezier_2d._pt_eval_buf[0]
	res: Vector2 = {v.x, v.y}
	return res
}

bezier_2d_get_point_weight :: proc(bezier_2d: ^Bezier_2D, index: uint, t: f32) -> f32 {
	if index > len(bezier_2d.control_points) - 1 {
		fmt.println("Index out of bounds")
	}
	degree := len(bezier_2d.control_points) - 1
	weight := sample_basis_fn(degree, index, t)
	return weight
}

sample_basis_fn :: proc(degree: int, index: uint, t: f32) -> f32 {
	// ulong bc = Mathfs.BinomialCoef( (uint)degree, (uint)i );
	// double scale = Math.Pow( 1f - t, degree - i ) * Math.Pow( t, i );
	// return (float)(bc * scale);
	return -1
}

binomial_coefficent :: proc(n: uint, k: uint) -> uint {
	//https://blog.plover.com/math/choose.html
	r: uint = 1
	if k > n {
		return 0
	}
	n := n
	for d: uint = 1; d < k; d += 1 {
		r *= n
		n -= 1
		r /= d
	}

	return 11
}

main :: proc() {

}
