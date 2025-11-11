extends State
class_name CrabKnockbackState

var duration: float = 0.25
var time_left: float = 0.0
var velocity: Vector3 = Vector3.ZERO
var damping: float = 30.0

func enter() -> void:
	# Duration and velocity should be set via start_knockback before entering
	if time_left <= 0.0:
		time_left = duration

func update(delta: float) -> void:
	if owner_node == null:
		return
	# Apply knockback motion
	owner_node.global_position += velocity * delta
	# Dampen velocity
	velocity = velocity.move_toward(Vector3.ZERO, damping * delta)
	# Countdown
	time_left -= delta
	if time_left <= 0.0:
		# Decide next state based on player distance
		var player := _get_player()
		if player:
			var dist: float = owner_node.global_position.distance_to(player.global_position)
			if dist <= owner_node.attack_range:
				request_transition("attack")
				return
			request_transition("run")
			return
		request_transition("idle")

func start_knockback(direction: Vector3, force: float, knockback_duration: float) -> void:
	# Normalize direction on XZ plane
	var flat_dir := Vector3(direction.x, 0.0, direction.z).normalized()
	velocity = flat_dir * force
	duration = knockback_duration
	time_left = knockback_duration

func _get_player() -> Node3D:
	return owner_node.get_tree().get_first_node_in_group("player")
