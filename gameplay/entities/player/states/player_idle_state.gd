extends State
class_name PlayerIdleState

func enter() -> void:
	# Play idle animation if any
	pass

func update(_delta: float) -> void:
	if owner_node == null:
		return
	# Transitions
	if owner_node.is_attack_pressed():
		request_transition("attack")
		return
	if owner_node.is_repair_pressed() and owner_node.can_repair():
		request_transition("repair")
		return
	if owner_node.is_jump_pressed():
		request_transition("jump")
		return
	var move: Vector3 = owner_node.get_move_input()
	if move.length() > 0.0:
		request_transition("run")
