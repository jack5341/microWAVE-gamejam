extends RefCounted
class_name State

signal transition_requested(new_state: String)

var owner_node: Node = null

func _init(owner_ref: Node = null) -> void:
	owner_node = owner_ref

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func request_transition(state_name: String) -> void:
	transition_requested.emit(state_name)
