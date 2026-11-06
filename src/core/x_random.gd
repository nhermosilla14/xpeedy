class_name XRandom
extends RefCounted
## Portable xoshiro128** generator (ADR 0004). Uses only 32-bit arithmetic so results are identical
## on every platform and Godot version.

const MASK32 := 0xFFFFFFFF

var _s: PackedInt64Array = PackedInt64Array([0, 0, 0, 0])


func _init(seed_value: int = 0) -> void:
	set_seed(seed_value)


func set_seed(seed_value: int) -> void:
	var x := seed_value & MASK32
	for i in 4:
		x = (x + 0x9E3779B9) & MASK32
		_s[i] = _mix32(x)
	if _s[0] == 0 and _s[1] == 0 and _s[2] == 0 and _s[3] == 0:
		_s[0] = 1


## Next unsigned 32-bit value.
func next_u32() -> int:
	var result := _mul32(_rotl(_mul32(_s[1], 5), 7), 9)
	var t := (_s[1] << 9) & MASK32
	_s[2] ^= _s[0]
	_s[3] ^= _s[1]
	_s[1] ^= _s[2]
	_s[0] ^= _s[3]
	_s[2] ^= t
	_s[3] = _rotl(_s[3], 11)
	return result


## Uniform float in [0, 1).
func next_float() -> float:
	return float(next_u32() >> 8) / 16777216.0


## Uniform integer in [from, to) — the reference's "random a–b" convention.
func range_int(from: int, to: int) -> int:
	if to <= from:
		return from
	return from + int(next_u32() % (to - from))


## Uniform float in [from, to).
func range_float(from: float, to: float) -> float:
	return from + (to - from) * next_float()


## True with probability `p`.
func chance(p: float) -> bool:
	return next_float() < p


static func _rotl(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK32


## (a * b) mod 2^32 without overflowing signed 64-bit integers.
static func _mul32(a: int, b: int) -> int:
	var lo := (a * (b & 0xFFFF)) & MASK32
	var hi := ((a * (b >> 16)) & 0xFFFF) << 16
	return (lo + hi) & MASK32


static func _mix32(z: int) -> int:
	z = _mul32(z ^ (z >> 16), 0x85EBCA6B)
	z = _mul32(z ^ (z >> 13), 0xC2B2AE35)
	return (z ^ (z >> 16)) & MASK32
