extends Node

func _ready():
    Signalbus.ship_sunk.connect(_on_ship_sunk)

func _on_ship_sunk():
    print("Ship sunk")