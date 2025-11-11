extends Control

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_health)

func update_health(health: int):
	progress_bar.value = lerp(progress_bar.value, health, 0.1)
