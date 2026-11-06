class_name ShieldStack
extends RefCounted
## The ship's shield units with one decay timer for the whole stack (doc 05).

var max_count: int
var decay_seconds: float
var count := 0
## Game time until the next unit is lost.
var time_left: float


func _init(max_units: int, decay: float) -> void:
	max_count = max_units
	decay_seconds = decay
	time_left = decay


## One more unit (up to the maximum). The timer restarts even when the stack is already full.
func add() -> void:
	count = mini(count + 1, max_count)
	time_left = decay_seconds


## Spends units; the timer restarts.
func lose(units: int) -> void:
	count = maxi(count - units, 0)
	time_left = decay_seconds


## Runs the decay timer: every expiry removes one unit and restarts it.
func tick(dt: float) -> void:
	if count == 0:
		time_left = decay_seconds
		return
	time_left -= dt
	while time_left <= 0.0:
		count -= 1
		time_left += decay_seconds
		if count == 0:
			time_left = decay_seconds
			return


## Remaining time as a fraction of the decay period, for the HUD.
func fraction() -> float:
	return clampf(time_left / decay_seconds, 0.0, 1.0)
