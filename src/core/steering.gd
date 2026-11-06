class_name Steering
extends RefCounted
## Steering pipeline from step 5 onwards (doc 03): response curve, then the invert option.

const RESPONSE_EXPONENT := 0.66

var invert := false


## Turns a raw input value (any sign) into a steer value. Positive steers right.
func process(raw: float) -> float:
	var steer := signf(raw) * pow(absf(raw), RESPONSE_EXPONENT)
	return -steer if invert else steer
