class_name Microwave extends Node3D

@export var what_is_inside: RawFood = null
@export var temperature: int = 0
@export var started: bool = false

@onready var plate: CSGCylinder3D = $Plate
@onready var light: SpotLight3D = $Light
@onready var door: Node3D = $Door
@onready var timer: Timer = $Timer
@onready var in_plate_raw_food: MeshInstance3D = $Plate/MeshInstance3D

var rotation_speed: float = 90.0  # degrees per second
var _session_over: bool = false
var _time_accumulator: float = 0.0

func _ready() -> void:
	# Setup timer
	if timer:
		timer.one_shot = true
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.timeout.connect(_on_timer_timeout)

	if not Signalbus.request_raw_food_cook.is_connected(_on_request_raw_food_cook):
		Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)

func _process(delta: float) -> void:
	_handle_session_timer(delta)
	_handle_rotate_plate(delta)
	_handle_light(delta)

func _handle_rotate_plate(delta: float) -> void:
	if started and what_is_inside != null:
		plate.rotate_y(deg_to_rad(rotation_speed * delta))

func _handle_light(_delta: float) -> void:
	if started:
		light.visible = true
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
	started = true
	temperature = raw.raw_temprature
	if timer:
		timer.start(max(0.0, raw.time_to_cook))

func _on_timer_timeout() -> void:
	started = false
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
