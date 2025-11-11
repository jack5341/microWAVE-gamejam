extends State
class_name PlayerRepairState

var time_left: float = 0.0

func enter() -> void:
	if owner_node:
		time_left = owner_node.repair_duration

func update(delta: float) -> void:
	if owner_node == null:
		return
	time_left -= delta
	if time_left <= 0.0:
		# Perform the actual repair (implementation TBD inside player)
		owner_node.perform_repair()
		var move: Vector3 = owner_node.get_move_input()
		request_transition("run" if move.length() > 0.0 else "idle")
