class_name RawFoodQueue extends Node

@onready var microwave: Microwave = $"../Microwave"

@export var max_queue_size: int = 5
@export var cycles_to_run: int = 5

var completed_cycles: int = 0
@export var available_raw_foods: Array[RawFood] = []

var _spawn_timer: Timer
var _refill_timer: Timer
var refill_cooldown_active: bool = false

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = 0.25
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_tick)
	_spawn_timer.start()
	# 3s cooldown before refilling after a cook completes
	_refill_timer = Timer.new()
	_refill_timer.one_shot = true
	_refill_timer.wait_time = 3.0
	add_child(_refill_timer)
	_refill_timer.timeout.connect(_on_refill_ready)
	Signalbus.food_cooked.connect(_on_food_cooked)

func _on_spawn_tick() -> void:
	if completed_cycles >= cycles_to_run:
		_spawn_timer.stop()
		return
	if refill_cooldown_active:
		return
	if microwave == null or not is_instance_valid(microwave):
		microwave = get_node_or_null("../Microwave")
		return
	# Skip if microwave is busy
	if microwave.started or microwave.what_is_inside != null:
		return
	if available_raw_foods.is_empty():
		return
	var raw: RawFood = available_raw_foods.pick_random()
	Signalbus.request_raw_food_cook.emit(raw)
	completed_cycles += 1

func _on_food_cooked(_food) -> void:
	# Start cooldown before the next refill
	refill_cooldown_active = true
	_refill_timer.start()

func _on_refill_ready() -> void:
	refill_cooldown_active = false
