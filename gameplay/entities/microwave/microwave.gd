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

func _ready() -> void:
	# Setup timer
	if timer:
		timer.one_shot = true
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.timeout.connect(_on_timer_timeout)

	if not Signalbus.request_raw_food_cook.is_connected(_on_request_raw_food_cook):
		Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)

func _process(delta: float) -> void:
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
			# Swap raw mesh to cooked result mesh on the existing MeshInstance3D
			if is_instance_valid(in_plate_raw_food):
				in_plate_raw_food.mesh = cooked.mesh
				in_plate_raw_food.scale = cooked.mesh_scale
				# Small vertical nudge to avoid z-fighting with plate, similar to previous behavior
				in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
			Global.score += 10
			Signalbus.food_cooked.emit(cooked)
			Signalbus.score_changed.emit(Global.score)
			
	# Remove the raw resource reference; keep the cooked mesh visible until next cycle
	what_is_inside = null
	# Always notify that the cooking cycle is completed so the queue can wait for Finish
	Signalbus.cooking_cycle_completed.emit()

var _result_mesh_instance: MeshInstance3D = null
