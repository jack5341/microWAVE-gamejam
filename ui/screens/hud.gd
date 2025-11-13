extends Control

@onready var score_label: Label = $TopBar/HBoxContainer/Score
@onready var countdown_label: Label = $TopBar/HBoxContainer/Countdown
@onready var hint_bar: Label = $HintBar/FinishHint

@onready var rpm_label: Label = $ControlPanel/HBoxContainer/VBoxContainer2/RPM
@onready var wattage_label: Label = $ControlPanel/HBoxContainer/VBoxContainer/Wattage
@onready var rpm_slider: VSlider = $ControlPanel/HBoxContainer/VBoxContainer2/VSlider
@onready var wattage_slider: VSlider = $ControlPanel/HBoxContainer/VBoxContainer/VSlider
@onready var guide: CenterContainer = $Guide

var last_displayed_score: int = -1
var last_displayed_seconds: int = -1

func _ready() -> void:
	_update_score(Global.score)
	_update_time(Global.time_remaining)

	Signalbus.score_changed.connect(_on_score_changed)
	Signalbus.time_remaining_changed.connect(_on_time_remaining_changed)
	Signalbus.waiting_for_finish_changed.connect(_on_waiting_for_finish_changed)	
	
	if guide != null:
		guide.visible = false

	if rpm_slider != null:
		rpm_slider.min_value = 0
		rpm_slider.max_value = 180
		rpm_slider.step = 10
		rpm_slider.value = 90 
		if not rpm_slider.value_changed.is_connected(_on_rpm_changed):
			rpm_slider.value_changed.connect(_on_rpm_changed)
		_update_rpm_label(rpm_slider.value)
		Signalbus.change_rpm_microwave.emit(rpm_slider.value)
	
	# Configure Wattage slider
	if wattage_slider != null:
		wattage_slider.min_value = 0
		wattage_slider.max_value = 200
		wattage_slider.step = 10
		wattage_slider.value = 100  # Default wattage
		if not wattage_slider.value_changed.is_connected(_on_wattage_changed):
			wattage_slider.value_changed.connect(_on_wattage_changed)
		_update_wattage_label(wattage_slider.value)
		Signalbus.change_power_microwave.emit(int(wattage_slider.value))

func _process(_delta: float) -> void:
	if Global.score != last_displayed_score:
		_update_score(Global.score)
	if Global.time_remaining != last_displayed_seconds:
		_update_time(Global.time_remaining)
	
	if guide != null:
		guide.visible = Input.is_action_pressed("guide")

func _on_score_changed(score: int) -> void:
	_update_score(score)

func _update_score(score: int) -> void:
	score_label.text = "🪙 %d" % score
	last_displayed_score = score

func _on_time_remaining_changed(seconds: int) -> void:
	_update_time(seconds)

func _update_time(seconds: int) -> void:
	var s: int = max(0, seconds)
	var mm: int = floori(s / 60.0)
	var ss: int = int(s % 60)
	countdown_label.text = "%02d:%02d" % [mm, ss]
	last_displayed_seconds = s

func _on_waiting_for_finish_changed(active: bool) -> void:
	if hint_bar == null:
		return
	hint_bar.visible = active

func _on_rpm_changed(value: float) -> void:
	_update_rpm_label(value)
	Signalbus.change_rpm_microwave.emit(value)

func _on_wattage_changed(value: float) -> void:
	_update_wattage_label(value)
	Signalbus.change_power_microwave.emit(int(value))

func _update_rpm_label(value: float) -> void:
	if rpm_label != null:
		rpm_label.text = "%.0f RPM" % value

func _update_wattage_label(value: float) -> void:
	if wattage_label != null:
		wattage_label.text = "%.0f W" % value
