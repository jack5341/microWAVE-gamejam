extends Node

@export var microwave: Microwave
@export var current_wattage: int = 100

var current_zone: int = 0
var remaining_time: float = 0.0
var initial_time: float = 0.0
var burn_level: float = 0.0
var blue_rate: float = 0.5
var green_rate: float = 1.0
var red_rate: float = 1.5
var burn_threshold: float = 2.5
var base_points: int = 10

var _timer: Timer = null

func _ready() -> void:
	Signalbus.change_power_microwave.connect(_on_change_power_microwave)
	
	if microwave == null:
		microwave = get_parent() as Microwave
	_timer = microwave.get_node_or_null("Timer") as Timer
	if _timer:
		_timer.one_shot = true
		if not _timer.timeout.is_connected(_on_timer_timeout):
			_timer.timeout.connect(_on_timer_timeout)
	if not Signalbus.request_raw_food_cook.is_connected(_on_request_raw_food_cook):
		Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)
	if not Signalbus.balance_zone_changed.is_connected(_on_balance_zone_changed):
		Signalbus.balance_zone_changed.connect(_on_balance_zone_changed)
	set_process(true)

func _on_change_power_microwave(wattage: int) -> void:
	current_wattage = wattage

func _process(delta: float) -> void:
	_handle_cook_progress(delta)

func _on_request_raw_food_cook(raw: RawFood) -> void:
	if microwave.started or microwave.what_is_inside != null:
		return
	if raw == null:
		return
	microwave.what_is_inside = raw
	if microwave.visual != null:
		microwave.visual.show_raw_food(raw)
	microwave.started = true
	remaining_time = max(0.0, raw.time_to_cook)
	initial_time = remaining_time
	burn_level = 0.0
	blue_rate = raw.blue_rate
	green_rate = raw.green_rate
	red_rate = raw.red_rate
	burn_threshold = raw.burn_time_threshold
	base_points = raw.base_points
	Signalbus.set_balance_bar_difficulty.emit(raw.difficulty_to_cook)
	if _timer:
		_timer.stop()
	if microwave.dialogues != null:
		microwave.dialogues.start_dialogue_loop(raw.dialogue_lines)

func _on_timer_timeout() -> void:
	if microwave.started:
		_finalize_cooking()

func _on_balance_zone_changed(zone: int) -> void:
	current_zone = zone

func _handle_cook_progress(delta: float) -> void:
	if microwave == null:
		return
	if not microwave.started or microwave.what_is_inside == null:
		return
	match current_zone:
		-1:
			remaining_time -= delta * blue_rate
		0:
			remaining_time -= delta * green_rate
		1:
			remaining_time -= delta * red_rate
			burn_level += delta
	remaining_time = clamp(remaining_time, 0.0, max(initial_time * 2.0, remaining_time))
	if remaining_time <= 0.0:
		_finalize_cooking()

func _finalize_cooking() -> void:
	microwave.started = false
	if microwave.dialogues != null:
		microwave.dialogues.stop_dialogue_loop()
	if microwave.what_is_inside != null:
		var raw_food: RawFood = microwave.what_is_inside
		var cooked: Food = raw_food.food
		if cooked != null:
			var raw_intensity01: float = clamp(remaining_time / max(initial_time, 0.0001), 0.0, 1.0)
			var burn_intensity01: float = clamp(burn_level / burn_threshold, 0.0, 1.0)
			var force_blue: bool = (current_zone == -1)
			if microwave.visual != null:
				microwave.visual.apply_finish_visual(raw_intensity01, burn_intensity01, cooked, raw_food, force_blue)
			var undercook_penalty: float = clamp(remaining_time / max(initial_time, 0.0001), 0.0, 2.0)
			var burn_penalty: float = clamp(burn_level / burn_threshold, 0.0, 1.0)
			var quality_ratio: float = clamp(1.0 - (microwave.undercook_weight * undercook_penalty + microwave.burn_weight * burn_penalty), 0.0, 1.0)
			var points: int = int(round(float(base_points) * quality_ratio))
			Global.score += max(0, points)
			Signalbus.food_cooked.emit(cooked)
			Signalbus.score_changed.emit(Global.score)
	microwave.what_is_inside = null
	Signalbus.cooking_cycle_completed.emit()
