class_name Enemy extends Node3D

@export var current_health: int = 100
@export var max_health: int = 100
@export var damage: int = 10
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 1.0

func _take_damage(amount: int):
	current_health -= amount
	if current_health < 0:
		current_health = 0 
		_die()

func _is_alive() -> bool:
	return current_health > 0

func _get_health() -> int:
	return current_health

func _die():
	Signalbus.enemy_killed.emit(self)

func _attack(target: Node3D):
	target.take_damage(damage)

func _attack_cooldown():
	await get_tree().create_timer(attack_cooldown).timeout

func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player")
