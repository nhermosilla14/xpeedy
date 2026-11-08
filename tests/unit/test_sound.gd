extends TestCase

const PATH := "user://test_sound_settings.cfg"


func _clean() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_every_sound_asset_loads_as_a_short_mono_16_bit_stream() -> void:
	for name in SoundPlayer.NAMES:
		var stream := load("res://assets/audio/%s.wav" % name) as AudioStreamWAV
		check(stream != null, "%s loads" % name)
		check(not stream.stereo, "%s is mono" % name)
		var seconds := stream.get_length()
		check(seconds > 0.03 and seconds < 1.0, "%s lasts %.2f s" % [name, seconds])
		check(not (SoundPlayer.VOLUMES.get(name, 99.0) > 0.0), "%s volume in range" % name)


func test_the_music_is_a_long_loop() -> void:
	var stream := load("res://assets/audio/music.wav") as AudioStreamWAV
	check(stream.get_length() > 8.0 and stream.get_length() < 40.0, "a loop of %.1f s" % stream.get_length())
	var player := SoundPlayer.new()
	player._ready()
	var loop := player._music.stream as AudioStreamWAV
	check_eq(loop.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	check_eq(loop.loop_end, int(round(stream.get_length() * stream.mix_rate)))
	check_eq(stream.mix_rate, 22050)
	player.free()


func test_each_event_of_doc_15_has_its_sound_and_vibration() -> void:
	var expected := {
		RunEvent.Kind.SHIELD_PICKUP: ["shieldup", 100],
		RunEvent.Kind.OBSTACLE_SMASHED: ["breakobs", 50],
		RunEvent.Kind.TORPEDO_HIT: ["breakobs", 0],
		RunEvent.Kind.ZONE_WARNING: ["warning", 50],
		RunEvent.Kind.BONUS_PICKUP: ["charge", 200],
		RunEvent.Kind.QUAKE: ["shockwave", 300],
		RunEvent.Kind.PLASMA_TOUCHED: ["powerdown", 100],
		RunEvent.Kind.TORPEDO_FIRED: ["torpedo", 50],
		RunEvent.Kind.RECHARGED: ["shieldup", 150],
		RunEvent.Kind.PHASE_STARTED: ["phase", 150],
		RunEvent.Kind.CRASH: ["crash", 500],
		RunEvent.Kind.RACE_FINISHED: ["finish", 0],
		RunEvent.Kind.RACE_STARTED: ["start", 0],
	}
	for kind in expected:
		var cue := SoundMap.for_event(kind)
		check_eq(cue.get("sound", ""), expected[kind][0], "sound of event %d" % kind)
		check_eq(cue.get("vibrate", -1), expected[kind][1], "vibration of event %d" % kind)
		check(SoundPlayer.NAMES.has(cue["sound"]), "%s exists" % cue["sound"])
	check(SoundMap.for_event(RunEvent.Kind.ZONE_SECOND).is_empty(), "countdown seconds are silent")
	check(SoundMap.for_event(RunEvent.Kind.BONUS_FIRED, SurvivalRun.Bonus.QUAKE).is_empty(), "a fired Quake has its own event")
	check_eq(SoundMap.for_event(RunEvent.Kind.BONUS_FIRED, SurvivalRun.Bonus.TIME_DILATION)["sound"], "phase")


func test_the_player_records_sounds_only_when_sound_is_on() -> void:
	var player := SoundPlayer.new()
	player._ready()
	player.play("click")
	check_eq(player.played, ["click"] as Array[String])
	player.set_options(false, true, true)
	player.play("crash")
	check_eq(player.played.size(), 1, "off: nothing is played")
	player.set_options(true, true, true)
	player.play("nope")
	check_eq(player.played.size(), 1, "an unknown sound is ignored")
	player.free()


func test_the_music_follows_its_option() -> void:
	var player := SoundPlayer.new()
	player._ready()
	player.start_music()
	check(player.is_music_playing(), "playing")
	player.set_options(true, false, true)
	check(not player.is_music_playing(), "stopped when off")
	player.set_options(true, true, true)
	check(player.is_music_playing(), "back on")
	player.set_options(true, false, true)
	player.start_music()
	check(not player.is_music_playing(), "start does nothing while off")
	player.free()


func test_vibration_follows_its_option() -> void:
	var player := SoundPlayer.new()
	player._ready()
	player.vibrate(100)
	player.vibrate(0)
	check_eq(player.vibrations, [100] as Array[int])
	player.set_options(true, true, false)
	player.vibrate(500)
	check_eq(player.vibrations.size(), 1)
	player.free()


func test_audio_settings_default_to_on_are_saved_and_ignore_bad_values() -> void:
	_clean()
	var settings := Settings.new(PATH)
	check(settings.sound and settings.music and settings.vibration, "all on by default")
	settings.sound = false
	settings.vibration = false
	settings.save()
	var again := Settings.new(PATH)
	check(not again.sound and again.music and not again.vibration, "saved")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[audio]\nsound=\"loud\"\nmusic=false\n")
	file.close()
	var bad := Settings.new(PATH)
	check(bad.sound, "a wrongly typed value counts as on")
	check(not bad.music, "a valid value is kept")
	_clean()


func test_the_settings_page_switches_audio_and_tells_the_owner() -> void:
	_clean()
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	var changes := []
	menu.settings_changed.connect(func() -> void: changes.append(1))
	menu.open(MenuController.Page.SETTINGS)
	for index in [2, 3, 4]:
		menu.move(index - menu.selected_index())
		menu.activate()
	check_eq(menu.page_item_texts().slice(2), ["sound: off", "music: off", "vibration: off"] as Array[String])
	check_eq(changes.size(), 3)
	var saved := Settings.new(PATH)
	check(not saved.sound and not saved.music and not saved.vibration, "saved")
	menu.free()
	_clean()


func test_menu_activation_asks_for_a_click() -> void:
	var menu := MenuController.new()
	menu.settings = Settings.new(PATH)
	menu._ready()
	var clicks := []
	menu.clicked.connect(func() -> void: clicks.append(1))
	menu.open(MenuController.Page.MAIN)
	menu.activate()
	check_eq(clicks.size(), 1)
	menu.back()
	check_eq(clicks.size(), 2)
	menu.free()
	_clean()
