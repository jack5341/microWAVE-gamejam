extends Node

@export var microwave: Microwave
@export var timer: Timer = null

var current_zone: int = 0
var remaining_time: float = 0.0
var initial_time: float = 0.0
var burn_level: float = 0.0
var blue_rate: float = 0.5
var green_rate: float = 1.0
var red_rate: float = 1.5
var burn_threshold: float = 2.5
var base_points: int = 10

var current_combo_multiplier: float = 1.0
var current_combo_streak: int = 0
var _finished_early: bool = false

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)
	Signalbus.balance_zone_changed.connect(_on_balance_zone_changed)
	Signalbus.zone_space_pressed.connect(_on_zone_space_pressed)
	set_process(true)

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
	_finished_early = false
	blue_rate = raw.blue_rate
	green_rate = raw.green_rate
	red_rate = raw.red_rate
	burn_threshold = raw.burn_time_threshold
	base_points = raw.base_points
	Signalbus.set_balance_bar_difficulty.emit(raw.difficulty_to_cook)
	timer.stop()
	if microwave.dialogues != null:
		microwave.dialogues.start_dialogue_loop(raw.dialogue_lines)

func _on_timer_timeout() -> void:
	if microwave.started:
		_finalize_cooking()

func _on_balance_zone_changed(zone: int) -> void:
	current_zone = zone

func _on_zone_space_pressed(zone: int) -> void:
	# If cooking is active and space pressed in blue or red zone, finish immediately
	if not microwave.started or microwave.what_is_inside == null:
		return
	
	# Blue zone (-1) = finish raw, Red zone (1) = finish burned
	if zone == -1 or zone == 1:
		_finish_early(zone)

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

func _finish_early(zone: int) -> void:
	# Force finish state based on zone
	_finished_early = true
	if zone == -1:  # Blue zone - finish raw
		remaining_time = initial_time  # Keep all remaining time = fully raw
		burn_level = 0.0  # No burn
		AudioManager.play_sfx(load("res://assets/audio/sfx/raw_cooked.mp3"))
	elif zone == 1:  # Red zone - finish burned
		remaining_time = 0.0  # Fully cooked 
		burn_level = burn_threshold  # Fully burned
		AudioManager.play_sfx(load("res://assets/audio/sfx/burned_cooked.mp3"))
	_finalize_cooking()

func _finalize_cooking() -> void:
	microwave.started = false
	if microwave.dialogues != null:
		microwave.dialogues.stop_dialogue_loop()
	if microwave.what_is_inside != null:
		var raw_food: RawFood = microwave.what_is_inside
		var cooked: Food = raw_food.food
		if cooked != null:
			var raw_intensity01: float
			var burn_intensity01: float
			
			# If cooking finished naturally (no early finish), make it perfect
			if not _finished_early:
				raw_intensity01 = 0.0  # Perfectly cooked, not raw
				burn_intensity01 = 0.0  # Perfectly cooked, not burned
			else:
				# Early finish - use calculated intensities
				raw_intensity01 = clamp(remaining_time / max(initial_time, 0.0001), 0.0, 1.0)
				burn_intensity01 = clamp(burn_level / burn_threshold, 0.0, 1.0)
			
			var force_blue: bool = (current_zone == -1)
			if microwave.visual != null:
				microwave.visual.apply_finish_visual(raw_intensity01, burn_intensity01, cooked, raw_food, force_blue)
			# Calculate penalties and points based on final state
			var points: int = 0
			if not _finished_early:
				# Perfect cooked - full points, no penalties
				var quality_ratio: float = 1.0  # Perfect quality
				points = int(round(float(base_points) * quality_ratio * max(1.0, current_combo_multiplier)))
				AudioManager.play_sfx(load("res://assets/audio/sfx/perfect_food.mp3"))
			else:
				# Early finish (failed) - no points
				points = 0
			Global.score += max(0, points)
			Signalbus.food_cooked.emit(cooked)
			Signalbus.score_changed.emit(Global.score)
	microwave.what_is_inside = null
	Signalbus.cooking_cycle_completed.emit()

func _on_combo_changed(streak: int, multiplier: float) -> void:
	current_combo_streak = max(0, streak)
	current_combo_multiplier = max(1.0, multiplier)
