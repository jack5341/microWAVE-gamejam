extends State
class_name CrabIdleState

@export var detection_range: float = 15.0

func enter() -> void:
	# Idle state - do nothing until player within detection range
	pass

func update(delta: float) -> void:
	if owner_node == null:
		return
	var player := _get_player()
	if player == null:
		return
	var dist: float = owner_node.global_position.distance_to(player.global_position)
	if dist <= detection_range:
		request_transition("run")

func _get_player() -> Node3D:
	return owner_node.get_tree().get_first_node_in_group("player")
