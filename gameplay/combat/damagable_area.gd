class_name DamagableArea extends Area3D

@export var damage_multiplier: float = 1.0
@export var owner_path: NodePath
@export var hit_cooldown_ms: int = 150

var owner_enemy: Enemy = null
var _last_hit_ms: int = -1

func _ready() -> void:
	owner_enemy = get_node_or_null(owner_path)
	if owner_enemy == null:
		owner_enemy = get_parent() as Enemy

func apply_hit(base_damage: int, from_direction: Vector3 = Vector3.ZERO, attack_id: int = 0) -> void:
	if owner_enemy == null:
		return
	var now := Time.get_ticks_msec()
	if hit_cooldown_ms > 0 and _last_hit_ms >= 0 and now - _last_hit_ms < hit_cooldown_ms:
		return
	_last_hit_ms = now
	var dmg := int(round(float(base_damage) * damage_multiplier))
	if owner_enemy.has_method("take_damage"):
		owner_enemy.take_damage(dmg, from_direction)