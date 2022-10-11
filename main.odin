package freya
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
import bsp2 "./bspline2"
import bz2 "./bezier2"
import "core:fmt"
import la "core:math/linalg"
import "core:math"
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

/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

main :: proc() {
	knots: []f32 = {0, 0, 0, 1, 2, 3, 3, 3}
	points: []Vector2 = {
		Vector2{0, 0},
		Vector2{1, 1},
		Vector2{0, 1},
		Vector2{2, -1},
		Vector2{3, 0},
	}
	b := bsp2.bspline_2d(points, knots, 2)
	fmt.println(b)
}
