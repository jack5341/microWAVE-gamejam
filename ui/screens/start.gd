extends Control

@onready var start_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# Load the main game scene
	get_tree().change_scene_to_file("res://gameplay/entities/microwave/microwave.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
