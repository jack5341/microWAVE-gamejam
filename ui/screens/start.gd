extends Control

@onready var start_button: Button = $CenterContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/StartButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	# Reset global state before starting
	Global.score = 0
	Global.time_remaining = 180 # 3 minutes default
	
	# Load the main game scene
	get_tree().change_scene_to_file("res://levels/testing/testing.tscn")
