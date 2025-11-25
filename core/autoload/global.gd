extends Node

@export var score: int = 0
@export var time_remaining: int = 180
var purchased_decorations: Array[String] = []

func is_decoration_purchased(decoration_name: String) -> bool:
	return decoration_name in purchased_decorations

func purchase_decoration(decoration_name: String) -> void:
	if not is_decoration_purchased(decoration_name):
		purchased_decorations.append(decoration_name)