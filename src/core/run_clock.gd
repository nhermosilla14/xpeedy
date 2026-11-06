class_name RunClock
extends RefCounted
## Game clock (docs 03, 17): caps frame stalls at 200 ms and supports scaling (Time Dilation).

const MAX_STEP := 0.2

var time := 0.0
var scale := 1.0
var _last_step := 1.0 / 60.0


## Advances by a real-time delta and returns the game-time delta applied.
func advance(real_delta: float) -> float:
	var step := real_delta
	if step > MAX_STEP:
		step = _last_step
	else:
		_last_step = step
	var game_delta := step * scale
	time += game_delta
	return game_delta
