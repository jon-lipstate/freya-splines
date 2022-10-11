
package bezier_2d
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
import "core:fmt"
import la "core:math/linalg"
import "core:math"
import spline_utils "../spline_utils"
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
lerp :: la.lerp
lerp_inv :: la.unlerp
Vector2 :: la.Vector2f32
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
start_pt :: proc(bezier_2d: ^Bezier_2D) -> Vector2 {
	return bezier_2d.control_points[0]
}
end_pt :: proc(bezier_2d: ^Bezier_2D) -> Vector2 {
	last_index := len(bezier_2d.control_points) - 1
	return bezier_2d.control_points[last_index]
}

count :: proc(bezier_2d: ^Bezier_2D) -> uint {
	return len(bezier_2d.control_points)
}

degree :: proc(bezier_2d: ^Bezier_2D) -> uint {
	return len(bezier_2d.control_points) - 1
}
get_point :: proc(bezier_2d: ^Bezier_2D, t: f32) -> Vector2 {
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

get_point_weight :: proc(bezier_2d: ^Bezier_2D, index: uint, t: f32) -> f32 {
	if index > len(bezier_2d.control_points) - 1 {
		fmt.println("Index out of bounds")
	}
	degree := len(bezier_2d.control_points) - 1
	weight := spline_utils.sample_basis_fn(uint(degree), index, t)
	return weight
}
