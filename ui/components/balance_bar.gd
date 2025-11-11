extends Control
class_name BalanceBar

@export var zone_width_ratio: float = 0.35
@export var arrow_speed: float = 500.0
@export var drift_speed: float = 60.0
@export var bar_height: int = 24
@export var arrow_width: int = 4

var bar: ColorRect
var zone: ColorRect
var arrow: ColorRect

var arrow_x: float = 0.0
var zone_left: float = 0.0
var zone_right: float = 0.0
var drift_dir: float = 1.0

func _ready() -> void:
	_find_or_create_children()
	arrow_x = size.x * 0.5
	_layout_elements()
	_update_zone_bounds()
	set_process(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_find_or_create_children()
		if bar != null and zone != null and arrow != null:
			_layout_elements()
			arrow_x = clamp(arrow_x, 0.0, size.x)
			_update_arrow_position()
			_update_zone_bounds()

func _process(delta: float) -> void:
	var input_dir := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		input_dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		input_dir += 1.0
	
	var velocity := input_dir * arrow_speed + drift_dir * drift_speed
	arrow_x = clamp(arrow_x + velocity * delta, 0.0, size.x)
	
	if arrow_x <= 0.0 or arrow_x >= size.x:
		drift_dir *= -1.0
	
	_update_arrow_position()

func _layout_elements() -> void:
	if bar == null or zone == null or arrow == null:
		return
	var bar_y := (size.y - bar_height) * 0.5
	bar.position = Vector2(0.0, bar_y)
	bar.size = Vector2(size.x, bar_height)
	
	var zone_w: float = max(8.0, size.x * clamp(zone_width_ratio, 0.05, 0.95))
	zone.position = Vector2((size.x - zone_w) * 0.5, bar_y)
	zone.size = Vector2(zone_w, bar_height)
	
	arrow.size = Vector2(arrow_width, bar_height + 8.0)
	arrow.position.y = bar_y - 4.0
	
	_update_zone_bounds()
	_update_arrow_position()

func _update_zone_bounds() -> void:
	if zone == null:
		return
	zone_left = zone.position.x
	zone_right = zone.position.x + zone.size.x

func _update_arrow_position() -> void:
	if arrow == null:
		return
	arrow.position.x = arrow_x - arrow_width * 0.5
	var inside := arrow_x >= zone_left and arrow_x <= zone_right
	arrow.color = Color(0.95, 0.95, 0.95, 1.0) if inside else Color(1.0, 0.4, 0.4, 1.0)

func _find_or_create_children() -> void:
	if bar == null:
		bar = get_node_or_null("Bar") as ColorRect
		if bar == null:
			bar = ColorRect.new()
			bar.name = "Bar"
			bar.color = Color(0.18, 0.18, 0.18, 1.0)
			add_child(bar)
	if zone == null:
		zone = get_node_or_null("Zone") as ColorRect
		if zone == null:
			zone = ColorRect.new()
			zone.name = "Zone"
			zone.color = Color(0.2, 0.75, 0.3, 0.55)
			add_child(zone)
	if arrow == null:
		arrow = get_node_or_null("Arrow") as ColorRect
		if arrow == null:
			arrow = ColorRect.new()
			arrow.name = "Arrow"
			arrow.color = Color(0.95, 0.95, 0.95, 1.0)
			add_child(arrow)
