extends Node3D
class_name Player

@onready var raycast: RayCast3D = get_node("RayCast3D")

@export var move_speed: float = 6.0
@export var roll_speed: float = 10.0
@export var jump_duration: float = 0.35
@export var roll_duration: float = 0.40
@export var attack_duration: float = 0.30
@export var hit_duration: float = 0.20
@export var repair_duration: float = 1.00

@export var current_health: int = 100
@export var max_health: int = 100


signal health_changed(health: int)

var states: Dictionary = {}
var current_state: State = null
var invulnerable: bool = false

func _ready() -> void:
	# States (preloaded)
	states["idle"] = preload("res://gameplay/entities/player/states/player_idle_state.gd").new(self)
	states["run"] = preload("res://gameplay/entities/player/states/player_run_state.gd").new(self)
	states["jump"] = preload("res://gameplay/entities/player/states/player_jump_state.gd").new(self)
	states["roll"] = preload("res://gameplay/entities/player/states/player_roll_state.gd").new(self)
	states["attack"] = preload("res://gameplay/entities/player/states/player_attack_state.gd").new(self)
	states["hit"] = preload("res://gameplay/entities/player/states/player_hit_state.gd").new(self)
	states["repair"] = preload("res://gameplay/entities/player/states/player_repair_state.gd").new(self)

	for s in states.values():
		s.transition_requested.connect(_on_state_transition)

	# Ensure grouped for lookups
	if not is_in_group("player"):
		add_to_group("player")

	_change_state("idle")

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _on_state_transition(next_state: String) -> void:
	_change_state(next_state)

func _change_state(state_name: String) -> void:
	if current_state:
		current_state.exit()
	current_state = states.get(state_name, null)
	if current_state:
		current_state.enter()

# ------------ Input helpers ------------
func get_move_input() -> Vector3:
	# Using standard WASD input actions; returns XZ plane direction
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var z := Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var v := Vector3(x, 0.0, z)
	return v.normalized() if v.length() > 1e-6 else Vector3.ZERO

func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack")

func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

func is_roll_pressed() -> bool:
	return Input.is_action_just_pressed("roll")

func is_repair_pressed() -> bool:
	return Input.is_action_just_pressed("repair")

# ------------ Actions invoked by gameplay ------------
func take_damage(amount: int, from_direction: Vector3 = Vector3.ZERO) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
		Signalbus.game_over.emit()

	if invulnerable:
		return

	# Forward to hit state
	var hit_state = states.get("hit")
	if hit_state:
		hit_state.set("incoming_damage", amount)
		hit_state.set("hit_direction", from_direction)
		_change_state("hit")
	health_changed.emit(current_health)

func perform_repair() -> void:
	if raycast.is_colliding():
		var collider: Node3D = raycast.get_collider()
		if collider is ShipPart:
			collider.repair(10)
