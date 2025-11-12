extends Control
class_name BalanceBar

enum Difficulty { EASY, MEDIUM, HARD }
enum Zone { BLUE = -1, GREEN = 0, RED = 1 }
@export var difficulty: Difficulty = Difficulty.MEDIUM: set = set_difficulty, get = get_difficulty
@export var zone_width_ratio: float = 0.35: set = set_zone_width_ratio, get = get_zone_width_ratio
@export var return_speed_ratio: float = 0.25
@export var bounce_duration: float = 0.15
@export var bounce_trans: int = Tween.TRANS_CUBIC
@export var bounce_ease: int = Tween.EASE_OUT

@onready var bar_content: Control = $"Center/BarContent"
@onready var zone: ColorRect = $"Center/BarContent/ZoneHBox/Zone"
@onready var arrow: ColorRect = $"Center/BarContent/ArrowLayer/Arrow"
@onready var left_spacer: Control = $"Center/BarContent/ZoneHBox/LeftSpacer"
@onready var right_spacer: Control = $"Center/BarContent/ZoneHBox/RightSpacer"

var arrow_ratio: float = 0.5
var zone_left_global: float = 0.0
var zone_right_global: float = 0.0
var bounce_ratio: float = 0.18
var _space_was_pressed: bool = false
var _is_bouncing: bool = false
var _bounce_tween: Tween = null
var _current_zone: int = Zone.BLUE

func _ready() -> void:
	# Start from far left
	arrow_ratio = 0.0
	_apply_difficulty()
	_apply_zone_layout()
	_update_zone_bounds()
	_update_arrow_position()
	set_process(true)
	if not Signalbus.set_balance_bar_difficulty.is_connected(_on_set_balance_bar_difficulty):
		Signalbus.set_balance_bar_difficulty.connect(_on_set_balance_bar_difficulty)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_zone_bounds()
		_update_arrow_position()

func _process(delta: float) -> void:
	# Discrete bounce to the right on Space press
	var pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if pressed and not _space_was_pressed:
		_bounce()
	_space_was_pressed = pressed
	
	# Constant drift back to the left (Flappy-Bird-style gravity)
	if not _is_bouncing:
		arrow_ratio = clamp(arrow_ratio - return_speed_ratio * delta, 0.0, 1.0)
	_update_arrow_position()
	_update_arrow_color()
	_emit_zone_if_changed()

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

func _bounce() -> void:
	var target: float = clamp(arrow_ratio + bounce_ratio, 0.0, 1.0)
	if is_equal_approx(target, arrow_ratio):
		return
	if _bounce_tween != null and is_instance_valid(_bounce_tween):
		_bounce_tween.kill()
	_bounce_tween = create_tween()
	_is_bouncing = true
	_bounce_tween.set_trans(bounce_trans).set_ease(bounce_ease)
	_bounce_tween.tween_property(self, "arrow_ratio", target, bounce_duration)
	_bounce_tween.tween_callback(Callable(self, "_on_bounce_finished"))

func reset_arrow() -> void:
	arrow_ratio = 0.0
	_update_arrow_position()
	_update_arrow_color()

func _on_bounce_finished() -> void:
	_is_bouncing = false
	_bounce_tween = null
	_update_arrow_position()
	_update_arrow_color()

func set_difficulty(value: int) -> void:
	difficulty = value as Difficulty
	_apply_difficulty()

func get_difficulty() -> int:
	return difficulty

func _apply_difficulty() -> void:
	# Harder: smaller green zone, bigger bounce
	match difficulty:
		Difficulty.EASY:
			set_zone_width_ratio(0.45)
			bounce_ratio = 0.12
			return_speed_ratio = 0.20
		Difficulty.MEDIUM:
			set_zone_width_ratio(0.35)
			bounce_ratio = 0.18
			return_speed_ratio = 0.25
		Difficulty.HARD:
			set_zone_width_ratio(0.22)
			bounce_ratio = 0.25
			return_speed_ratio = 0.32

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
