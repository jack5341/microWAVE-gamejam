class_name Microwave extends Node3D

@export var what_is_inside: RawFood = null
@export var temperature: int = 0
@export var started: bool = false
@export var green_cook_rate: float = 1.0
@export var blue_uncook_rate: float = 0.75
@export var red_cook_rate: float = 1.5
@export var blue_cook_rate: float = 0.5
@export var undercook_weight: float = 0.75
@export var burn_weight: float = 0.25
@export var burn_threshold: float = 2.5

@onready var plate: CSGCylinder3D = $Plate
@onready var light: SpotLight3D = $Light
@onready var door: Node3D = $Door
@onready var timer: Timer = $Timer
@onready var in_plate_raw_food: MeshInstance3D = $Plate/MeshInstance3D
@onready var dialogue_label: Label = $HudLayer/ChatBubble/CenterContainer/MarginContainer/Label

var rotation_speed: float = 90.0
var _session_over: bool = false
var _time_accumulator: float = 0.0
var _remaining_time: float = 0.0
var _initial_time: float = 0.0
var _burn_level: float = 0.0
var _current_zone: int = 0
var _blue_rate: float = 0.5
var _green_rate: float = 1.0
var _red_rate: float = 1.5
var _burn_threshold: float = 2.5
var _base_points: int = 10
var _dialogue_timer: Timer = null
var _dialogue_lines: Array[String] = []

func _ready() -> void:
	AudioManager.play_music_from_path("res://assets/audio/music/lofi.mp3")

	# Setup timer
	if timer:
		timer.one_shot = true
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.timeout.connect(_on_timer_timeout)

	if not Signalbus.request_raw_food_cook.is_connected(_on_request_raw_food_cook):
		Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)
	if not Signalbus.balance_zone_changed.is_connected(_on_balance_zone_changed):
		Signalbus.balance_zone_changed.connect(_on_balance_zone_changed)

func _process(delta: float) -> void:
	_handle_session_timer(delta)
	_handle_cook_progress(delta)
	_handle_rotate_plate(delta)
	_handle_light(delta)

func _handle_rotate_plate(delta: float) -> void:
	if started and what_is_inside != null:
		plate.rotate_y(deg_to_rad(rotation_speed * delta))

func _handle_light(_delta: float) -> void:
	if started:
		light.visible = true
		match _current_zone:
			-1:
				light.light_color = Color(0.2, 0.4, 0.9)
			0:
				light.light_color = Color(0.2, 0.8, 0.3)
			1:
				light.light_color = Color(1.0, 0.25, 0.2)
	else:
		light.visible = false

func _on_request_raw_food_cook(raw: RawFood) -> void:
	if started or what_is_inside != null:
		return
	if raw == null:
		return
	if _result_mesh_instance != null and is_instance_valid(_result_mesh_instance):
		_result_mesh_instance.queue_free()
		_result_mesh_instance = null
	what_is_inside = raw
	in_plate_raw_food.mesh = what_is_inside.mesh
	in_plate_raw_food.scale = what_is_inside.mesh_scale
	in_plate_raw_food.position = what_is_inside.mesh_position
	# Clear any previous visual overrides/tints
	if is_instance_valid(in_plate_raw_food):
		in_plate_raw_food.material_override = null
	started = true
	temperature = raw.raw_temprature
	_remaining_time = max(0.0, raw.time_to_cook)
	_initial_time = _remaining_time
	_burn_level = 0.0
	# Pull per-item tuning from data (fallback to defaults if needed)
	_blue_rate = raw.blue_rate
	_green_rate = raw.green_rate
	_red_rate = raw.red_rate
	_burn_threshold = raw.burn_time_threshold
	_base_points = raw.base_points
	Signalbus.set_balance_bar_difficulty.emit(raw.difficulty_to_cook)
	if timer:
		timer.stop()
	_start_dialogue_loop(raw.dialogue_lines)

func _on_timer_timeout() -> void:
	started = false
	_stop_dialogue_loop()
	if what_is_inside != null:
		var cooked: Food = what_is_inside.food
		if cooked != null:
			if is_instance_valid(in_plate_raw_food):
				in_plate_raw_food.mesh = cooked.mesh
				in_plate_raw_food.scale = cooked.mesh_scale
				in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
			Global.score += 10
			Signalbus.food_cooked.emit(cooked)
			Signalbus.score_changed.emit(Global.score)
			
	what_is_inside = null
	Signalbus.cooking_cycle_completed.emit()

var _result_mesh_instance: MeshInstance3D = null

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

func _on_balance_zone_changed(zone: int) -> void:
	_current_zone = zone

func _handle_cook_progress(delta: float) -> void:
	if not started or what_is_inside == null:
		return
	match _current_zone:
		-1:
			_remaining_time -= delta * _blue_rate
		0:
			_remaining_time -= delta * _green_rate
		1:
			_remaining_time -= delta * _red_rate
			_burn_level += delta
	_remaining_time = clamp(_remaining_time, 0.0, max(_initial_time * 2.0, _remaining_time))
	if _remaining_time <= 0.0:
		_finalize_cooking()

func _finalize_cooking() -> void:
	started = false
	_stop_dialogue_loop()
	if what_is_inside != null:
		var cooked: Food = what_is_inside.food
		if cooked != null:
			if is_instance_valid(in_plate_raw_food):
				in_plate_raw_food.mesh = cooked.mesh
				in_plate_raw_food.scale = cooked.mesh_scale
				in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
			# Compute intensities for visuals and score
			var raw_intensity01: float = clamp(_remaining_time / max(_initial_time, 0.0001), 0.0, 1.0)
			var burn_intensity01: float = clamp(_burn_level / _burn_threshold, 0.0, 1.0)
			var force_blue: bool = (_current_zone == -1)
			_apply_finish_visual(raw_intensity01, burn_intensity01, cooked, force_blue)
			var undercook_penalty: float = clamp(_remaining_time / max(_initial_time, 0.0001), 0.0, 2.0)
			var burn_penalty: float = clamp(_burn_level / _burn_threshold, 0.0, 1.0)
			var quality_ratio: float = clamp(1.0 - (undercook_weight * undercook_penalty + burn_weight * burn_penalty), 0.0, 1.0)
			var points: int = int(round(float(_base_points) * quality_ratio))
			Global.score += max(0, points)
			Signalbus.food_cooked.emit(cooked)
			Signalbus.score_changed.emit(Global.score)
	what_is_inside = null
	Signalbus.cooking_cycle_completed.emit()

func _apply_finish_visual(raw_intensity: float, burn_intensity: float, cooked: Food, force_blue: bool = false) -> void:
	if not is_instance_valid(in_plate_raw_food) or cooked == null or cooked.mesh == null:
		return
	var threshold: float = 0.01
	var apply_burn: bool = (not force_blue) and burn_intensity > raw_intensity and burn_intensity > threshold
	var apply_raw: bool = force_blue or (raw_intensity >= burn_intensity and raw_intensity > threshold)
	if not apply_burn and not apply_raw:
		return
	var src_mesh: ArrayMesh = cooked.mesh
	var dupe_mesh: ArrayMesh = src_mesh.duplicate()
	if dupe_mesh == null:
		return
	var surface_count: int = dupe_mesh.get_surface_count()
	var blue_tint: Color = Color(0.3, 0.55, 1.0, 1.0)
	var blue_strength: float = (max(raw_intensity, 0.6) if force_blue else raw_intensity)
	for i in range(surface_count):
		var base_mat: Material = dupe_mesh.surface_get_material(i)
		var new_mat: StandardMaterial3D = null
		if base_mat != null and base_mat is StandardMaterial3D:
			new_mat = base_mat.duplicate()
		else:
			new_mat = StandardMaterial3D.new()
		if apply_burn:
			var d: float = clamp(1.0 - 0.7 * burn_intensity, 0.0, 1.0)
			new_mat.albedo_color = Color(d, d, d, 1.0)
		elif apply_raw:
			new_mat.albedo_color = Color(1, 1, 1, 1.0).lerp(blue_tint, blue_strength)
		dupe_mesh.surface_set_material(i, new_mat)
	in_plate_raw_food.mesh = dupe_mesh
	# Ensure the blue look is clearly visible even if source materials/textures dominate
	if apply_raw:
		var override_mat: StandardMaterial3D = StandardMaterial3D.new()
		override_mat.albedo_color = Color(1, 1, 1, 1.0).lerp(blue_tint, blue_strength)
		in_plate_raw_food.material_override = override_mat
	elif apply_burn:
		# Use surface materials for burn darkening
		in_plate_raw_food.material_override = null

func _start_dialogue_loop(dialogue_lines: Array[String]) -> void:
	if dialogue_label == null:
		return
	if dialogue_lines == null or dialogue_lines.is_empty():
		dialogue_label.visible = false
		dialogue_label.text = ""
		return
	_dialogue_lines = dialogue_lines
	# Show immediately with a random line
	dialogue_label.visible = true
	dialogue_label.text = _dialogue_lines[randi() % _dialogue_lines.size()]
	# Create/update timer
	if _dialogue_timer == null:
		_dialogue_timer = Timer.new()
		_dialogue_timer.one_shot = false
		_dialogue_timer.wait_time = 2.5
		add_child(_dialogue_timer)
		_dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)
	_dialogue_timer.start()

func _stop_dialogue_loop() -> void:
	if _dialogue_timer != null:
		_dialogue_timer.stop()
		_dialogue_timer.queue_free()
		_dialogue_timer = null
	if dialogue_label != null:
		dialogue_label.visible = false
		dialogue_label.text = ""
	_dialogue_lines.clear()

func _on_dialogue_timer_timeout() -> void:
	if not started or what_is_inside == null:
		_stop_dialogue_loop()
		return
	if dialogue_label == null:
		return
	if _dialogue_lines.is_empty():
		dialogue_label.visible = false
		dialogue_label.text = ""
		return
	dialogue_label.visible = true
	dialogue_label.text = _dialogue_lines[randi() % _dialogue_lines.size()]
