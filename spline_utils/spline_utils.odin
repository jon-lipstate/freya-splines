package utils
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
import "core:math"
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
sample_basis_fn :: proc(degree: uint, index: uint, t: f32) -> f32 {
	bc := binomial_coefficent(degree, index)
	scale := math.pow(1. - t, f32(degree - index)) * math.pow(t, f32(index))
	return f32(bc) * scale
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
