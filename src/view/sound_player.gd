class_name SoundPlayer
extends Node
## Plays the effects and the music, and vibrates (ADR 0031). Each of the three can be switched off; a player
## that is off does nothing. `played` and `vibrations` record what was asked, for tests.

const NAMES := ["click", "beep", "start", "shieldup", "breakobs", "warning", "charge", "shockwave", "powerdown",
	"torpedo", "crash", "finish", "phase"]
## Effect volumes in dB (doc 15 mixes at 0.5 to 1.0).
const VOLUMES := {"click": -6.0, "beep": -4.0, "start": -2.0, "shieldup": -3.0, "breakobs": -2.0, "warning": -4.0,
	"charge": -3.0, "shockwave": 0.0, "powerdown": -2.0, "torpedo": -3.0, "crash": 0.0, "finish": -2.0, "phase": -4.0}
const MUSIC_DB := -9.0
const POOL := 8
const RECORD_LIMIT := 64

var sound_enabled := true
var music_enabled := true
var vibration_enabled := true
var played: Array[String] = []
var vibrations: Array[int] = []

var _streams := {}
var _voices: Array[AudioStreamPlayer] = []
var _music := AudioStreamPlayer.new()
## Headless runs (the tests) record what would play but make no sound: playbacks still alive at exit are
## reported as leaked resources.
var _silent := DisplayServer.get_name() == "headless"
var _music_on := false


func _ready() -> void:
	for name in NAMES:
		_streams[name] = load("res://assets/audio/%s.wav" % name)
	for i in POOL:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	var loop: AudioStreamWAV = (load("res://assets/audio/music.wav") as AudioStreamWAV).duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	# Imported WAVs may be compressed (QOA), so the end is measured in samples from the length.
	loop.loop_end = int(round(loop.get_length() * loop.mix_rate))
	_music.stream = loop
	_music.volume_db = MUSIC_DB
	add_child(_music)


## Lets go of the streams so no resource outlives the player (headless runs report them at exit).
func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_music.stop()
	_music.stream = null
	_streams.clear()


func set_options(sound: bool, music: bool, vibration: bool) -> void:
	sound_enabled = sound
	music_enabled = music
	vibration_enabled = vibration
	_apply_music()


## Starts the soundtrack (if the music is on); it loops until the music is switched off.
func start_music() -> void:
	_apply_music()


func is_music_playing() -> bool:
	return _music_on


func _apply_music() -> void:
	if music_enabled and not _music_on:
		_music_on = true
		if not _silent:
			_music.play()
	elif not music_enabled and _music_on:
		_music_on = false
		_music.stop()


func play(name: String) -> void:
	if not sound_enabled or not _streams.has(name):
		return
	played.append(name)
	if played.size() > RECORD_LIMIT:
		played.pop_front()
	if _silent:
		return
	for voice in _voices:
		if not voice.playing:
			voice.stream = _streams[name]
			voice.volume_db = VOLUMES.get(name, 0.0)
			voice.play()
			return


## Vibrates for `ms` milliseconds where the device can (Android); a no-op elsewhere.
func vibrate(ms: int) -> void:
	if not vibration_enabled or ms <= 0:
		return
	vibrations.append(ms)
	if vibrations.size() > RECORD_LIMIT:
		vibrations.pop_front()
	Input.vibrate_handheld(ms)
