extends State
class_name CrabRunState

@export var move_speed: float = 4.0

func enter() -> void:
	# Could play run animation here
	pass

func update(delta: float) -> void:
	if owner_node == null:
		return
	var player := _get_player()
	if player == null:
		request_transition("idle")
		return
	var to_player: Vector3 = player.global_position - owner_node.global_position
	var flat_dir := Vector3(to_player.x, 0.0, to_player.z).normalized()
	# Move toward player on XZ plane
	owner_node.global_position += flat_dir * move_speed * delta
	# Face the player (optional)
	if flat_dir.length() > 0.0:
		owner_node.look_at(Vector3(player.global_position.x, owner_node.global_position.y, player.global_position.z), Vector3.UP)
	# Transition to attack if within attack range
	var dist: float = owner_node.global_position.distance_to(player.global_position)
	var attack_range: float =  owner_node.attack_range if owner_node.has_method("attack_range") == false else owner_node.attack_range
	if dist <= attack_range:
		request_transition("attack")

func _get_player() -> Node3D:
	return owner_node.get_tree().get_first_node_in_group("player")
