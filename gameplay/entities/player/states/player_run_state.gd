extends State
class_name PlayerRunState

func enter() -> void:
	# Play run animation if any
	pass

func update(delta: float) -> void:
	if owner_node == null:
		return
	# Movement
	var move: Vector3 = owner_node.get_move_input()
	if move.length() > 0.0:
		owner_node.global_position += move * owner_node.move_speed * delta
		owner_node.look_at(owner_node.global_position + move, Vector3.UP)

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
	if owner_node.is_roll_pressed():
		request_transition("roll")
		return
	if move.length() == 0.0:
		request_transition("idle")
