extends Node3D

@export var max_health: int = 100
@export var current_health: int = 100
@export var damageable_areas: Array[ShipPart] = []
@export var sinking_speed: float = 1.0
@export var sinking: bool = false
@export var max_water_level: float = 100.0
@export var water_level: float = 0.0
@export var repair_bail_amount: float = 10.0
@export var leak_spike_amount: float = 2.0
@export var sink_depth: float = 2.0
@export var buoyancy_lerp_speed: float = 3.0

var _broken_count: int = 0
var _broken_parts := {}
var _health_drain_buffer: float = 0.0
var _base_y: float = 0.0

func _ready():
	for area in damageable_areas:
		area.part_broken.connect(_on_part_broken)
		area.part_repaired.connect(_on_part_repaired)
		if area.is_broken():
			if not _broken_parts.has(area):
				_broken_parts[area] = true
				_broken_count += 1
	_base_y = position.y

func _on_part_broken(part: ShipPart):
	if not _broken_parts.has(part):
		_broken_parts[part] = true
		_broken_count += 1
	_increase_water_level(leak_spike_amount)

func _on_part_repaired(part: ShipPart):
	if _broken_parts.has(part):
		_broken_parts.erase(part)
		_broken_count = max(_broken_count - 1, 0)

func _process(delta):
	if _broken_count > 0:
		var amount: float = sinking_speed * float(_broken_count) * delta
		_increase_water_level(amount)
		_health_drain_buffer += amount
		while _health_drain_buffer >= 1.0 and current_health > 0:
			current_health -= 1
			_health_drain_buffer -= 1.0

	if current_health <= 0:
		Signalbus.game_over.emit()
		return

	var water_ratio: float = 0.0
	if max_water_level > 0.0:
		water_ratio = clamp(water_level / max_water_level, 0.0, 1.0)
	var target_y: float = _base_y - (sink_depth * water_ratio)
	var t: float = min(buoyancy_lerp_speed * delta, 1.0)
	position.y = lerp(position.y, target_y, t)

func _increase_water_level(amount: float):
	water_level = clamp(water_level + amount, 0.0, max_water_level)
	Signalbus.ship_water_level_increased.emit(amount)

func _decrease_water_level(amount: float):
	water_level = clamp(water_level - amount, 0.0, max_water_level)
	Signalbus.ship_water_level_decreased.emit(amount)

func _get_water_level() -> float:
	return water_level

func boil_water(amount: float = repair_bail_amount) -> void:
	_decrease_water_level(amount)
