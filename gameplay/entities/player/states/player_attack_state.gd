extends State
class_name PlayerAttackState

var time_left: float = 0.0

func enter() -> void:
	if owner_node:
		time_left = owner_node.attack_duration

func update(delta: float) -> void:
	if owner_node == null:
		return
	# Perform attack here (spawn hitbox, etc.)
	time_left -= delta
	if time_left <= 0.0:
		var move: Vector3 = owner_node.get_move_input()
		request_transition("run" if move.length() > 0.0 else "idle")
