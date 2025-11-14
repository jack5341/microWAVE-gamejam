class_name Microwave extends Node3D

@export var what_is_inside: RawFood = null
@export var started: bool = false
@export var undercook_weight: float = 0.75
@export var burn_weight: float = 0.25

@onready var cooking: Node = $Cooking
@onready var dialogues: Node = $Dialogues
@onready var visual: Node = $Visual
@onready var camera: Camera3D = $Camera3D
@onready var guide_map: MeshInstance3D = $GuideMap

# Guide view configuration
@export_group("Guide View")
@export var guide_camera_position: Vector3 = Vector3(-0.046, 0.0, -0.234)
@export var guide_camera_rotation_degrees: Vector3 = Vector3(0.0, -90.0, 0.0)
@export var guide_camera_tween_duration: float = 0.35
@export var default_camera_position: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var default_camera_rotation_degrees: Vector3 = Vector3(0.0, 0.0, 0.0)

# Camera shake configuration
@export_group("Camera Shake")
@export var shake_enabled: bool = true
@export var shake_duration_red: float = 0.5
@export var shake_amplitude_red: float = 0.01
@export var shake_duration_settle: float = 0.15
@export var shake_amplitude_settle: float = 0.0025
@export var shake_sustain_on_red: bool = true
@export var shake_sustain_duration: float = 0.12
@export var shake_sustain_amplitude: float = 0.003

# Camera guide view state
var _guide_view_active: bool = false
var _camera_original_transform: Transform3D
var _camera_tween: Tween = null
var _cam_start_rot: Vector3
var _cam_target_rot: Vector3

# Camera shake state
var _shake_time: float = 0.0
var _shake_total: float = 0.0
var _shake_amp: float = 0.0
var _shake_prev_offset: Vector3 = Vector3.ZERO
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _session_over: bool = false
var _time_accumulator: float = 0.0

func _ready() -> void:
	AudioManager.play_music_from_path("res://assets/audio/music/lofi.mp3")
	await get_tree().process_frame
	AudioManager.set_bus_volume_db(AudioManager.music_bus_name, -30)
	if not Signalbus.guide_mode_changed.is_connected(_on_guide_mode_changed):
		Signalbus.guide_mode_changed.connect(_on_guide_mode_changed)
	if not Signalbus.balance_zone_changed.is_connected(_on_zone_changed):
		Signalbus.balance_zone_changed.connect(_on_zone_changed)
	_shake_rng.randomize()

func _process(delta: float) -> void:
	_handle_session_timer(delta)
	_update_camera_shake(delta)

func get_current_zone() -> int:
	if cooking != null and "current_zone" in cooking:
		return cooking.current_zone
	return 0

func _handle_session_timer(delta: float) -> void:
	if _session_over:
		return
	if Global.time_remaining <= 0:
		_end_session()
		return
	_time_accumulator += delta
	if _time_accumulator >= 1.0:
		var seconds_to_subtract: int = int(_time_accumulator)
		_time_accumulator -= float(seconds_to_subtract)
		var new_time: int = max(0, Global.time_remaining - seconds_to_subtract)
		if new_time != Global.time_remaining:
			Global.time_remaining = new_time
			Signalbus.time_remaining_changed.emit(Global.time_remaining)
		if Global.time_remaining == 0:
			_end_session()

func _end_session() -> void:
	_session_over = true
	var game_over_scene: PackedScene = load("res://ui/screens/game_over.tscn")
	if game_over_scene:
		var overlay: Control = game_over_scene.instantiate()
		var hud_layer: CanvasLayer = get_node_or_null("HudLayer")
		if hud_layer:
			hud_layer.add_child(overlay)
		else:
			add_child(overlay)

func _handle_guide_view() -> void:
	var should_activate: bool = Input.is_action_pressed("guide")
	if should_activate and not _guide_view_active:
		_activate_guide_view()
	elif not should_activate and _guide_view_active:
		_deactivate_guide_view()

func _activate_guide_view() -> void:
	if camera == null:
		return
	_guide_view_active = true
	_camera_original_transform = camera.transform
	# Target transform from exported properties
	var target_position: Vector3 = guide_camera_position
	var target_rotation_degrees: Vector3 = guide_camera_rotation_degrees
	# Tween to target
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(camera, "position", target_position, guide_camera_tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Smooth shortest-path rotation using lerp_angle on radians
	_cam_start_rot = camera.rotation
	_cam_target_rot = Vector3(
		deg_to_rad(target_rotation_degrees.x),
		deg_to_rad(target_rotation_degrees.y),
		deg_to_rad(target_rotation_degrees.z)
	)
	_camera_tween.tween_method(_set_camera_rotation_t, 0.0, 1.0, guide_camera_tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _deactivate_guide_view() -> void:
	if camera == null:
		return
	_guide_view_active = false
	# Tween back to original transform
	if _camera_tween != null:
		_camera_tween.kill()
	var orig_pos: Vector3 = default_camera_position
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(camera, "position", orig_pos, guide_camera_tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Smooth shortest-path rotation back using lerp_angle on radians
	_cam_start_rot = camera.rotation
	_cam_target_rot = Vector3(
		deg_to_rad(default_camera_rotation_degrees.x),
		deg_to_rad(default_camera_rotation_degrees.y),
		deg_to_rad(default_camera_rotation_degrees.z)
	)
	_camera_tween.tween_method(_set_camera_rotation_t, 0.0, 1.0, guide_camera_tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_camera_rotation_t(t: float) -> void:
	if camera == null:
		return
	var rx: float = lerp_angle(_cam_start_rot.x, _cam_target_rot.x, t)
	var ry: float = lerp_angle(_cam_start_rot.y, _cam_target_rot.y, t)
	var rz: float = lerp_angle(_cam_start_rot.z, _cam_target_rot.z, t)
	camera.rotation = Vector3(rx, ry, rz)

func _on_guide_mode_changed(active: bool) -> void:
	if active:
		_activate_guide_view()
	else:
		_deactivate_guide_view()

func _on_zone_changed(zone: int) -> void:
	if not shake_enabled:
		return
	if zone == 1:
		_start_camera_shake(shake_duration_red, shake_amplitude_red)
	else:
		_start_camera_shake(shake_duration_settle, shake_amplitude_settle)

func _start_camera_shake(duration: float, amplitude: float) -> void:
	_shake_time = max(_shake_time, duration)
	_shake_total = max(_shake_total, duration)
	_shake_amp = max(_shake_amp, amplitude)

func _update_camera_shake(delta: float) -> void:
	if camera == null or not shake_enabled:
		return
	# Sustain a baseline shake while in RED, if enabled
	if shake_sustain_on_red and get_current_zone() == 1:
		_start_camera_shake(shake_sustain_duration, shake_sustain_amplitude)
	# Remove last frame's offset to avoid drifting against tweens
	if _shake_prev_offset != Vector3.ZERO:
		camera.position -= _shake_prev_offset
		_shake_prev_offset = Vector3.ZERO
	if _shake_time <= 0.0:
		return
	_shake_time = max(0.0, _shake_time - delta)
	var t: float = (_shake_time / _shake_total) if (_shake_total > 0.0) else 0.0
	var strength: float = _shake_amp * (t * t) # ease-out falloff
	var ox: float = _shake_rng.randf_range(-1.0, 1.0) * strength
	var oy: float = _shake_rng.randf_range(-1.0, 1.0) * strength
	_shake_prev_offset = Vector3(ox, oy, 0.0)
	camera.position += _shake_prev_offset
	if _shake_time == 0.0:
		_shake_total = 0.0
		_shake_amp = 0.0
