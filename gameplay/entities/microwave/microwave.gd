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

@onready var door: Node3D = $Door
@onready var cooking: Node = $Cooking
@onready var dialogues: Node = $Dialogues
@onready var visual: Node = $Visual

var _session_over: bool = false
var _time_accumulator: float = 0.0

func _ready() -> void:
	AudioManager.play_music_from_path("res://assets/audio/music/lofi.mp3")
	await get_tree().process_frame
	AudioManager.set_bus_volume_db(AudioManager.music_bus_name, -20)

func _process(delta: float) -> void:
	_handle_session_timer(delta)

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
