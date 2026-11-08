extends SceneTree
## End-to-end check for slices 0043 and 0044 through the real scene: the music is on, the start lights beep and
## racing starts with its sound, pick-ups, a smash, a crash and a finish play their sounds, the panel and menu
## choices click, and with sound off a run records nothing.

enum Phase { START, EVENTS, CHOICE, MUTED, DONE }

var _main: Node
var _phase := Phase.START
var _ticks := 0
var _errors: PackedStringArray = []


func _initialize() -> void:
	_main = load("res://src/main.tscn").instantiate()
	_main.set("options", LaunchOptions.parse(PackedStringArray([])))
	_main.set("start_in_menu", false)
	_main.set("obstacles_enabled", false)
	_main.set("show_warning", false)
	root.add_child(_main)
	_main.set("_settings", Settings.new("user://e2e_sound_settings.cfg"))
	_main.set("_economy", Economy.new("user://e2e_sound_economy.cfg"))
	_main.set("_progress", StageProgress.new("user://e2e_sound_stages.cfg"))


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	var sound: SoundPlayer = _main.get_node("Sound")
	var run: SurvivalRun = _main.get("_run")
	match _phase:
		Phase.START:
			if _ticks == 2:
				if not sound.is_music_playing():
					_errors.append("the music is not playing")
				_main.call("start_run", 5)
				_phase = Phase.EVENTS
				_ticks = 0
		Phase.EVENTS:
			if _ticks == 300:
				var beeps := sound.played.count("beep")
				if beeps != 3 or not sound.played.has("start"):
					_errors.append("start sequence sounds wrong: %s" % [sound.played])
				run = _main.get("_run")
				run.spots.add(Spot.make(int(run.track.segment) + 4, 7))
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 12, 7, Obstacle.Kind.CUBE, 0))
				run.shields.add()
				run.shields.add()
				run.track.p = 1.0 - 7.5 / 8.0
			if _ticks == 420:
				if not sound.played.has("shieldup") or not sound.played.has("breakobs"):
					_errors.append("pick-up and smash sounds missing: %s" % [sound.played])
				if sound.vibrations.is_empty():
					_errors.append("no vibration was asked for")
				run.shields.count = 0
				run.obstacles.add(Obstacle.make(int(run.track.segment) + 4, 7, Obstacle.Kind.CUBE, 1))
			if _ticks == 520:
				if not sound.played.has("crash"):
					_errors.append("no crash sound")
				_phase = Phase.CHOICE
				_ticks = 0
		Phase.CHOICE:
			if _ticks == 1:
				sound.played.clear()
				_main.call("_on_choice", 0)
			if _ticks == 3:
				if not sound.played.has("click"):
					_errors.append("a panel choice did not click")
				(_main.get("_settings") as Settings).sound = false
				_main.call("_apply_audio_settings")
				sound.played.clear()
				_main.call("start_run", 6)
				_phase = Phase.MUTED
				_ticks = 0
		Phase.MUTED:
			if _ticks == 300:
				var muted: SurvivalRun = _main.get("_run")
				muted.track.crash("obstacle")
				muted.take_events()
				_main.call("_show_events")
			if _ticks == 320:
				if not sound.played.is_empty():
					_errors.append("sounds were recorded with sound off: %s" % [sound.played])
				return _finish()
	if _ticks > 800:
		_errors.append("timed out in phase %s" % Phase.keys()[_phase])
		return _finish()
	return false


func _finish() -> bool:
	for name in ["settings", "economy", "stages"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://e2e_sound_%s.cfg" % name))
	if _errors.is_empty():
		print("  ok    e2e sound (music, start lights, pick-up, smash, crash, clicks, muted)")
		quit(0)
	else:
		for e in _errors:
			print("  FAIL  e2e sound: %s" % e)
		quit(1)
	return true
