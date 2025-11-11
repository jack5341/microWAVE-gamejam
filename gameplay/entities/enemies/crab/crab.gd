class_name Crab extends Enemy

var states: Dictionary = {}
var current_state: State = null

func _ready() -> void:
	# Instantiate states
	states["idle"] = preload("res://gameplay/entities/enemies/crab/states/crab_idle_state.gd").new(self)
	states["run"] = preload("res://gameplay/entities/enemies/crab/states/crab_run_state.gd").new(self)
	states["attack"] = preload("res://gameplay/entities/enemies/crab/states/crab_attack_state.gd").new(self)
	states["knockback"] = preload("res://gameplay/entities/enemies/crab/states/crab_knockback_state.gd").new(self)
	# Connect transitions
	for s in states.values():
		s.transition_requested.connect(_on_state_transition)
	# Start in idle
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

func apply_knockback(direction: Vector3, force: float = 10.0, duration: float = 0.25) -> void:
	var kb = states.get("knockback")
	if kb:
		kb.start_knockback(direction, force, duration)
		_change_state("knockback")
