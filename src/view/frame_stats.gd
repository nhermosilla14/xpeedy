class_name FrameStats
extends Node
## Benchmark logger (slice 0002): prints average fps and 1 % low to stdout every REPORT_SECONDS,
## which PortMaster captures in the port's log.txt.

const REPORT_SECONDS := 10.0

## Optional `func() -> String` with extra state to log next to the frame rate.
var extra: Callable

var _frame_times: PackedFloat32Array = []
var _since_report := 0.0
var _total_time := 0.0


func _process(delta: float) -> void:
	_frame_times.append(delta)
	_since_report += delta
	_total_time += delta
	if _since_report >= REPORT_SECONDS:
		print(summary())
		_frame_times.clear()
		_since_report = 0.0


## "t=… avg=… fps low1%=… fps" for the frames collected since the last report.
func summary() -> String:
	var text := "[bench] t=%.0fs %s" % [_total_time, describe(_frame_times)]
	if extra.is_valid():
		text += " | " + str(extra.call())
	return text


static func describe(frame_times: PackedFloat32Array) -> String:
	if frame_times.is_empty():
		return "no frames"
	var sorted := frame_times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in sorted:
		total += t
	var p99: float = sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))]
	return "avg=%.1f fps low1%%=%.1f fps frames=%d" % [
		sorted.size() / total, 1.0 / p99, sorted.size()]
