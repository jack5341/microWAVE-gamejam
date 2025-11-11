extends State
class_name PlayerJumpState

var time_left: float = 0.0

func enter() -> void:
	# Start jump timer
	if owner_node:
		time_left = owner_node.jump_duration

func update(delta: float) -> void:
	if owner_node == null:
		return
	# Count down jump time
	time_left -= delta
	if time_left <= 0.0:
		# Decide next state based on input
		var move: Vector3 = owner_node.get_move_input()
		request_transition("run" if move.length() > 0.0 else "idle")
