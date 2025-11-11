extends State
class_name CrabAttackState

var cooldown_timer: float = 0.0

func enter() -> void:
	cooldown_timer = 0.0

func update(delta: float) -> void:
	if owner_node == null:
		return
	cooldown_timer += delta
	var player := _get_player()
	if player == null:
		request_transition("idle")
		return
	var dist: float = owner_node.global_position.distance_to(player.global_position)
	if dist > owner_node.attack_range:
		request_transition("run")
		return
	# Attack if cooldown is ready
	if cooldown_timer >= owner_node.attack_cooldown:
		cooldown_timer = 0.0
		_perform_attack(player)

func _perform_attack(target: Node3D) -> void:
	if owner_node.has_method("_attack"):
		owner_node._attack(target)

func _get_player() -> Node3D:
	return owner_node.get_tree().get_first_node_in_group("player")
