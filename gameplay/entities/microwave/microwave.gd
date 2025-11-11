class_name Microwave extends Node3D

@export var what_is_inside: Food = null
@export var temperature: int = 0
@export var door_open: bool = true
@export var started: bool = false

@onready var plate: CSGCylinder3D = $Plate
@onready var light: SpotLight3D = $Light

@onready var door: Node3D = $Door

var rotation_speed: float = 90.0  # degrees per second

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_handle_rotate_plate(delta)
	_handle_light(delta)

func _handle_rotate_plate(delta: float) -> void:
	if started and door_open:
		plate.rotate_y(deg_to_rad(rotation_speed * delta))

func _handle_light(delta: float) -> void:
	if started and door_open:
		light.visible = true
	else:
		light.visible = false
