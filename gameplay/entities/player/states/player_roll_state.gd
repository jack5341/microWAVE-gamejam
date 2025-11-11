extends State
class_name PlayerRollState

var time_left: float = 0.0
var roll_dir: Vector3 = Vector3.ZERO

func enter() -> void:
	if owner_node:
		owner_node.invulnerable = true
		roll_dir = owner_node.get_move_input()
		if roll_dir.length() == 0.0:
			roll_dir = owner_node.transform.basis.z.normalized()
		time_left = owner_node.roll_duration

func exit() -> void:
	if owner_node:
		owner_node.invulnerable = false

func update(delta: float) -> void:
	if owner_node == null:
		return
	owner_node.global_position += roll_dir * owner_node.roll_speed * delta
	time_left -= delta
	if time_left <= 0.0:
		var move: Vector3 = owner_node.get_move_input()
		request_transition("run" if move.length() > 0.0 else "idle")
