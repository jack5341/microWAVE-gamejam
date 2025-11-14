extends Control
class_name BalanceBar

enum Difficulty { EASY, MEDIUM, HARD }
enum Zone { BLUE = -1, GREEN = 0, RED = 1 }
@export var difficulty: Difficulty = Difficulty.MEDIUM: set = set_difficulty, get = get_difficulty
@export var zone_width_ratio: float = 0.35: set = set_zone_width_ratio, get = get_zone_width_ratio

@export_category("Combo")
@export var combo_max_multiplier: float = 2.0
@export var combo_growth_rate: float = 0.23

@onready var bar_content: Control = $"Center/BarContent"
@onready var zone: ColorRect = $"Center/BarContent/ZoneHBox/Zone"
@onready var arrow: ColorRect = $"Center/BarContent/ArrowLayer/Arrow"
@onready var left_spacer: Control = $"Center/BarContent/ZoneHBox/LeftSpacer"
@onready var right_spacer: Control = $"Center/BarContent/ZoneHBox/RightSpacer"

var arrow_ratio: float = 0.0
var zone_left_global: float = 0.0
var zone_right_global: float = 0.0
var _space_was_pressed: bool = false
var _current_zone: int = Zone.BLUE
var streak: int = 0
var combo_input_enabled: bool = false
var _current_balance_speed: float = 1.0  # Current speed from food config
var _movement_direction: int = 1  # 1 = left to right, -1 = right to left

func _ready() -> void:
	# Start from far left
	arrow_ratio = 0.0
	_apply_difficulty()
	_apply_zone_layout()
	_update_zone_bounds()
	_update_arrow_position()
	set_process(true)
	Signalbus.set_balance_bar_difficulty.connect(_on_set_balance_bar_difficulty)
	Signalbus.request_raw_food_cook.connect(_on_request_raw_food_cook)
	Signalbus.cooking_cycle_completed.connect(_on_cooking_cycle_completed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_zone_bounds()
		_update_arrow_position()

func _process(delta: float) -> void:
	# Continuous left-to-right-to-left movement (pendulum)
	if combo_input_enabled:
		arrow_ratio += _current_balance_speed * _movement_direction * delta
		# Reverse direction at edges
		if arrow_ratio >= 1.0:
			arrow_ratio = 1.0
			_movement_direction = -1  # Reverse to right-to-left
		elif arrow_ratio <= 0.0:
			arrow_ratio = 0.0
			_movement_direction = 1  # Reverse to left-to-right
	
	# Check space press for combo (no bounce)
	var pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if pressed and not _space_was_pressed and combo_input_enabled:
		var current_zone_at_press: int = _get_current_arrow_zone()
		var inside: bool = _is_arrow_inside_green()
		if inside:
			streak += 1
		else:
			streak = 0
		Signalbus.combo_changed.emit(streak, _compute_multiplier(streak))
		# Trigger camera shake if space pressed in red or blue zone
		if current_zone_at_press == Zone.RED or current_zone_at_press == Zone.BLUE:
			Signalbus.zone_space_pressed.emit(current_zone_at_press)
	_space_was_pressed = pressed
	
	_update_arrow_position()
	_update_arrow_color()
	_emit_zone_if_changed()

func _is_arrow_inside_green() -> bool:
	if arrow == null:
		return false
	var arrow_center_x: float = arrow.global_position.x + arrow.size.x * 0.5
	return arrow_center_x >= zone_left_global and arrow_center_x <= zone_right_global

func _get_current_arrow_zone() -> int:
	if arrow == null:
		return Zone.GREEN
	var arrow_center_x: float = arrow.global_position.x + arrow.size.x * 0.5
	if arrow_center_x < zone_left_global:
		return Zone.BLUE
	elif arrow_center_x > zone_right_global:
		return Zone.RED
	return Zone.GREEN

func _compute_multiplier(s: int) -> float:
	# Smooth, diminishing-returns curve approaching combo_max_multiplier
	var s_f: float = float(max(0, s))
	var gain: float = 1.0 - exp(-s_f * max(0.0, combo_growth_rate))
	return clamp(1.0 + (combo_max_multiplier - 1.0) * gain, 1.0, max(1.0, combo_max_multiplier))

func _on_request_raw_food_cook(raw: RawFood) -> void:
	combo_input_enabled = true
	if raw != null:
		_current_balance_speed = raw.balance_speed
		# Reset arrow to start from left, moving right
		arrow_ratio = 0.0
		_movement_direction = 1

func _on_cooking_cycle_completed() -> void:
	combo_input_enabled = false
	# Reset arrow position when cooking stops
	arrow_ratio = 0.0

func _update_zone_bounds() -> void:
	if zone == null:
		return
	zone_left_global = zone.global_position.x
	zone_right_global = zone_left_global + zone.size.x

func _update_arrow_position() -> void:
	if arrow == null or bar_content == null:
		return
	var x: float = bar_content.global_position.x + arrow_ratio * bar_content.size.x - arrow.size.x * 0.5
	arrow.global_position.x = x
	# Vertically center the arrow in BarContent
	arrow.global_position.y = bar_content.global_position.y + (bar_content.size.y - arrow.size.y) * 0.5

func _update_arrow_color() -> void:
	if arrow == null:
		return
	var arrow_center_x: float = arrow.global_position.x + arrow.size.x * 0.5
	var inside: bool = arrow_center_x >= zone_left_global and arrow_center_x <= zone_right_global
	arrow.color = Color(0.95, 0.95, 0.95, 1.0) if inside else Color(1.0, 0.4, 0.4, 1.0)

func set_zone_width_ratio(ratio: float) -> void:
	zone_width_ratio = clamp(ratio, 0.0, 1.0)
	_apply_zone_layout()
	_update_zone_bounds()
	_update_arrow_color()

func get_zone_width_ratio() -> float:
	return zone_width_ratio

func _apply_zone_layout() -> void:
	if left_spacer == null or right_spacer == null or zone == null:
		return
	var clamped_zone_ratio: float = clamp(zone_width_ratio, 0.0, 1.0)
	var side_ratio: float = max(0.0, (1.0 - clamped_zone_ratio) * 0.5)
	left_spacer.size_flags_stretch_ratio = side_ratio
	right_spacer.size_flags_stretch_ratio = side_ratio
	zone.size_flags_stretch_ratio = clamped_zone_ratio

func reset_arrow() -> void:
	arrow_ratio = 0.0
	_update_arrow_position()
	_update_arrow_color()

func set_difficulty(value: int) -> void:
	difficulty = value as Difficulty
	_apply_difficulty()

func get_difficulty() -> int:
	return difficulty

func _apply_difficulty() -> void:
	# Harder: smaller green zone
	match difficulty:
		Difficulty.EASY:
			set_zone_width_ratio(0.45)
		Difficulty.MEDIUM:
			set_zone_width_ratio(0.35)
		Difficulty.HARD:
			set_zone_width_ratio(0.22)

func _emit_zone_if_changed() -> void:
	if arrow == null:
		return
	var arrow_center_x: float = arrow.global_position.x + arrow.size.x * 0.5
	var new_zone: int = Zone.GREEN
	if arrow_center_x < zone_left_global:
		new_zone = Zone.BLUE
	elif arrow_center_x > zone_right_global:
		new_zone = Zone.RED
	if new_zone != _current_zone:
		_current_zone = new_zone
		Signalbus.balance_zone_changed.emit(_current_zone)

func _on_set_balance_bar_difficulty(level: int) -> void:
	var lvl: int = clamp(level, 1, 3)
	match lvl:
		1:
			set_difficulty(Difficulty.EASY)
		2:
			set_difficulty(Difficulty.MEDIUM)
		3:
			set_difficulty(Difficulty.HARD)
