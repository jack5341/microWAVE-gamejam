extends State
class_name PlayerHitState

var time_left: float = 0.0
var incoming_damage: int = 0
var hit_direction: Vector3 = Vector3.ZERO

func enter() -> void:
	if owner_node:
		time_left = owner_node.hit_duration
		owner_node.invulnerable = true

func exit() -> void:
	if owner_node:
		owner_node.invulnerable = false

func update(delta: float) -> void:
	if owner_node == null:
		return
	# Optional small knockback
	if hit_direction.length() > 0.0:
		var flat := Vector3(hit_direction.x, 0.0, hit_direction.z).normalized()
		owner_node.global_position += flat * 2.0 * delta
	
	time_left -= delta
	if time_left <= 0.0:
		var move: Vector3 = owner_node.get_move_input()
		request_transition("run" if move.length() > 0.0 else "idle")
