extends Control

@onready var score_label: Label = $MarginContainer/HBoxContainer/Score
@onready var countdown_label: Label = $MarginContainer/HBoxContainer/Countdown

func _ready() -> void:
	_update_score(Global.score)
	Signalbus.score_changed.connect(_on_score_changed)
	_update_time(Global.time_remaining)
	Signalbus.time_remaining_changed.connect(_on_time_remaining_changed)

func _on_score_changed(score: int) -> void:
	_update_score(score)

func _update_score(score: int) -> void:
	score_label.text = "🪙 %d" % score

func _on_time_remaining_changed(seconds: int) -> void:
	_update_time(seconds)

func _update_time(seconds: int) -> void:
	var s: int = max(0, seconds)
	var mm: int = floori(s / 60.0)
	var ss: int = int(s % 60)
	countdown_label.text = "%02d:%02d" % [mm, ss]
