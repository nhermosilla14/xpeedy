class_name SteerInput
extends RefCounted
## Reads the steering (ADR 0033): the keys and the d-pad through the `steer_left` and `steer_right` actions, and
## the left stick's horizontal axis directly, so the stick's direction can be flipped on devices that report
## it the other way round.

const DEADZONE := 0.2


## Steering in [-1, 1]; positive steers right. `flip_stick` reverses the stick only.
static func read(flip_stick: bool) -> float:
	var buttons := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var stick := 0.0
	for pad in Input.get_connected_joypads():
		stick = stick_value(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), flip_stick)
		if stick != 0.0:
			break
	return clampf(buttons + stick, -1.0, 1.0)


## One axis reading after the dead zone (the rest is scaled back to 0..1) and the optional flip.
static func stick_value(axis: float, flip: bool) -> float:
	var magnitude := absf(axis)
	if magnitude <= DEADZONE:
		return 0.0
	var scaled := (magnitude - DEADZONE) / (1.0 - DEADZONE)
	var value := signf(axis) * scaled
	return -value if flip else value
