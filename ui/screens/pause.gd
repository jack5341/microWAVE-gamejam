extends Control

@onready var resume_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	# Unpause the game
	get_tree().paused = false
	queue_free()

func _on_restart_pressed() -> void:
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	# Unpause and quit to main menu or exit
	get_tree().paused = false
	get_tree().quit()
