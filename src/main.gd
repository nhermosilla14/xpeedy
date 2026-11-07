extends Node3D
## Entry point: runs a Survival run at a fixed 60 Hz, draws it, and restarts after a crash.

## Tests and the benchmark can turn obstacles off before calling `start_run`.
var obstacles_enabled := true
## Tests turn the start sequence, the saved best and the panels off.
var countdown_enabled := true
## Tests turn the menu off too: the scene then starts a run on load.
var start_in_menu := true

## Seconds after a crash before the Game Over panel shows (the flash plays first).
const GAME_OVER_DELAY := 1.0

var _run: SurvivalRun
var _track: TrackModel
var _clock: RunClock
var _steering := Steering.new()
var _binding: TrackShaderBinding
var _trail_texture := TrailTexture.new()
## Launch options; tests can set them before the scene is added to the tree.
var options: LaunchOptions
var _restart_wait := 0.0
var _shot_time := 0.0
var _paused := false
## The Survival difficulty of the current run (a `Difficulty` key).
var difficulty := Difficulty.STANDARD
var _best := PersonalBest.new()
var _plain := false
var _over_shown := false
var _in_menu := false

@onready var _tunnel: TunnelView = $Tunnel
@onready var _obstacles: ObstacleView = $Obstacles
@onready var _explosions: ExplosionView = $Explosions
@onready var _camera: ShipCamera = $Camera
@onready var _fps: Label = $Hud/Fps
@onready var _lights: StartLights = $Hud/Lights
@onready var _screen: ScreenPanel = $Hud/Screen
@onready var _menu: MenuController = $Hud/Menu
@onready var _status: Hud = $Hud/Status
@onready var _flash: ScreenFlash = $Hud/Flash
@onready var _frame_stats: FrameStats = $FrameStats


func _ready() -> void:
	$Environment.environment = ShipCamera.make_environment()
	var materials: Array[ShaderMaterial] = [_tunnel.material, _obstacles.material, _explosions.material]
	_binding = TrackShaderBinding.new(materials)
	_binding.window_changed.connect(_tunnel.on_window_changed)
	_binding.window_changed.connect(_obstacles.on_window_changed)
	_binding.window_changed.connect(_explosions.on_window_changed)
	_tunnel.material.set_shader_parameter("trail_tex", _trail_texture.texture)
	if options == null:
		options = LaunchOptions.parse(OS.get_cmdline_user_args())
	Engine.time_scale = options.timescale
	_fps.visible = options.fps or options.benchmark
	UiFont.apply(_fps, 10)
	_status.pause_pressed.connect(_toggle_pause)
	_screen.chosen.connect(_on_choice)
	_frame_stats.extra = _state_text
	_menu.play_requested.connect(_on_play_requested)
	_menu.quit_requested.connect(get_tree().quit)
	difficulty = options.difficulty if Difficulty.is_valid(options.difficulty) else Difficulty.STANDARD
	if start_in_menu and options.starts_in_menu():
		enter_menu(MenuController.Page.DIFFICULTY if options.screen == "difficulty" else MenuController.Page.MAIN)
	else:
		start_run(_new_seed())


func _new_seed() -> int:
	if options.run_seed >= 0:
		return options.run_seed
	return int(Time.get_unix_time_from_system() * 1000.0) & 0xFFFFFFFF


## Shows the menu and drops the run: the world and the HUD are hidden and nothing steps.
func enter_menu(page: MenuController.Page) -> void:
	_in_menu = true
	_paused = false
	_run = null
	_screen.close()
	_menu.preferred_difficulty = difficulty
	_menu.open(page)
	_set_menu_visible(true)


func _set_menu_visible(menu: bool) -> void:
	_in_menu = menu
	for node in [_tunnel, _obstacles, _explosions, _status, _lights, $Hud/Flash]:
		node.visible = not menu
	_menu.visible = menu


func _on_play_requested(key: String) -> void:
	difficulty = key
	start_run(_new_seed())


func start_run(run_seed: int) -> void:
	_set_menu_visible(false)
	var config := Difficulty.config(difficulty)
	config.generate_obstacles = obstacles_enabled and not options.clean
	config.generate_spots = not options.clean
	_plain = countdown_enabled and options.is_plain_run()
	config.countdown = _plain
	config.collisions_enabled = not options.ghost
	config.crash_on_obstacles = not options.invulnerable
	config.start_shields = options.shields
	config.start_segment = _start_segment(run_seed)
	_run = SurvivalRun.new(config, run_seed)
	_track = _run.track
	_clock = RunClock.new()
	_binding.reset()
	_explosions.clear()
	_camera.reset()
	_screen.close()
	_paused = false
	_over_shown = false
	_restart_wait = 0.0
	if _plain:
		_status.show_best(_best.get_best(PersonalBest.key(difficulty)))
	print("[run] seed=%d" % run_seed)
	_refresh_view(0.0)


func _physics_process(delta: float) -> void:
	if _in_menu:
		_menu.poll()
		return
	if _track.crashed:
		if _handle_game_over_input():
			return
	elif Input.is_action_just_pressed("pause"):
		_toggle_pause()
		return
	if _paused:
		_navigate_panel()
		return
	var raw := Autopilot.plough(_run) if options.autopilot == "plough" else Input.get_axis("steer_left", "steer_right")
	var dt := _clock.advance(delta)
	if options.benchmark and _track.crashed:
		_restart_wait += dt
		if _restart_wait > 1.5:
			start_run(_track.seed_value + 1)
			return
	_run.step(dt, _steering.process(raw))
	_show_events()
	_show_game_over()
	_refresh_view(dt)


## Up/down move the panel's selection, accept confirms it. Returns true when the input was handled.
func _navigate_panel() -> bool:
	if Input.is_action_just_pressed("ui_down"):
		_screen.move_selection(1)
	elif Input.is_action_just_pressed("ui_up"):
		_screen.move_selection(-1)
	elif Input.is_action_just_pressed("ui_accept"):
		_on_choice(_screen.selected)
	elif Input.is_action_just_pressed("restart"):
		start_run(_track.seed_value + 1)
	else:
		return false
	return true


## After a crash: before the panel shows, restart restarts at once; with the panel, it is navigated and
## back goes to the main menu. Returns true when the input was handled and the tick is over.
func _handle_game_over_input() -> bool:
	if not _screen.visible:
		if Input.is_action_just_pressed("restart"):
			start_run(_track.seed_value + 1)
			return true
		return false
	if Input.is_action_just_pressed("ui_cancel"):
		enter_menu(MenuController.Page.MAIN)
		return true
	_navigate_panel()
	return true


func _toggle_pause() -> void:
	if _track.crashed:
		return
	_paused = not _paused
	if _paused:
		_screen.open("pause", [] as Array[String], ["resume game", "restart", "main menu"] as Array[String])
	else:
		_screen.close()


func _on_choice(index: int) -> void:
	if _paused:
		match index:
			0:
				_toggle_pause()
			1:
				start_run(_track.seed_value + 1)
			_:
				enter_menu(MenuController.Page.MAIN)
	elif _track.crashed:
		if index == 0:
			start_run(_track.seed_value + 1)
		else:
			enter_menu(MenuController.Page.MAIN)


## Once the crash flash is over, shows the Game Over panel and records the personal best.
func _show_game_over() -> void:
	if not (_plain and _track.crashed) or _over_shown or _track.crash_time < GAME_OVER_DELAY:
		return
	_over_shown = true
	var key := PersonalBest.key(difficulty)
	_best.submit(key, _run.score)
	_screen.open("game over", ["score: %d" % _run.score, "personal best: %d" % _best.get_best(key)] as Array[String],
		["new game", "main menu"] as Array[String])


## Feedback for what happened this tick (ADR 0010).
func _show_events() -> void:
	for event in _run.take_events():
		match event.kind:
			RunEvent.Kind.SHIELD_PICKUP:
				_flash.flash(Color(1.0, 0.7, 0.2), 0.75, 0.3)
			RunEvent.Kind.OBSTACLE_SMASHED:
				_flash.flash(Color(1.0, 0.5, 0.5), 0.75, 0.3)
				_explosions.spawn(_obstacle_centre(event.obstacle), event.obstacle.colour, _clock.time)
			RunEvent.Kind.CRASH:
				_flash.flash(Color.WHITE, 1.0, 1.0)


## World position of the middle of an obstacle, where its explosion starts.
func _obstacle_centre(o: Obstacle) -> Vector3:
	var geometry := _track.geometry
	var height := (2.5 if o.kind == Obstacle.Kind.BEAM else 0.5) * TrackModel.SEGMENT_LENGTH
	var lane := o.lane + 0.5
	var seg := o.seg + 0.5
	return geometry.surface(lane, seg) + geometry.normal(lane, seg) * height


## Where the run starts: `--start-segment`, or well inside the first part of the shape asked for with
## `--start-shape` (past the 30-segment morph).
func _start_segment(run_seed: int) -> float:
	var shapes := {"in": PartSequence.Shape.IN, "flat": PartSequence.Shape.FLAT, "out": PartSequence.Shape.OUT}
	if not shapes.has(options.start_shape):
		return options.start_segment
	if options.start_shape == "in":
		return 100.0
	var parts := PartSequence.new(run_seed)
	for i in range(1, 100):
		if parts.shape(i) == shapes[options.start_shape]:
			return float(parts.start(i)) + 50.0
	return options.start_segment


## What the benchmark log shows next to the frame rate, to tell how dense the track was.
func _state_text() -> String:
	if _run == null:
		return "menu"
	var level := ObstacleField.level_at(maxi(_track.window_start(), 0))
	return "segment=%d level=%d obstacles=%d shields=%d score=%d" % [
		_track.window_start(), level, _run.obstacles.all().size(), _run.shields.count, _run.score]


func _process(delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()
	if options.screenshot_path != "":
		_shot_time += delta
		if _shot_time >= options.screenshot_seconds:
			_capture(options.screenshot_path)
			options.screenshot_path = ""


## Saves what is on screen to a PNG and quits.
func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[screenshot] %s" % path)
	get_tree().quit()


func _refresh_view(dt: float) -> void:
	_binding.refresh(_track)
	_obstacles.refresh(_run.obstacles)
	_trail_texture.refresh(_run.trails)
	_status.update(_run)
	_lights.update(_run)
	_explosions.set_time(_clock.time)
	_camera.follow(_track, dt)
