extends Control

@export_category("Guide Fade")
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.3

@onready var score_label: Label = $TopBar/HBoxContainer/Score
@onready var countdown_label: Label = $TopBar/HBoxContainer/Countdown
@onready var finish_hint_label: Label = $TextBar/FinishHint
@onready var dialogues_label: Label = $TextBar/Dialogues
@onready var text_bar: Panel = $TextBar

@onready var rpm_label: Label = $ControlPanel/HBoxContainer/RPMBar/RPM
@onready var wattage_label: Label = $ControlPanel/HBoxContainer/WattageBar/Wattage
@onready var rpm_slider: VSlider = $ControlPanel/HBoxContainer/RPMBar/VSlider
@onready var wattage_slider: VSlider = $ControlPanel/HBoxContainer/WattageBar/VSlider

@onready var combo_label: Label = $ControlPanel/HBoxContainer/Control/ComboLabel

@onready var guide: CenterContainer = $Guide

var last_displayed_score: int = -1
var last_displayed_seconds: int = -1
var _guide_fade_tween: Tween = null
var _combo_tween: Tween = null
var _combo_last_streak: int = 0

func _ready() -> void:
	_update_score(Global.score)
	_update_time(Global.time_remaining)

	Signalbus.score_changed.connect(_on_score_changed)
	Signalbus.time_remaining_changed.connect(_on_time_remaining_changed)
	Signalbus.waiting_for_finish_changed.connect(_on_waiting_for_finish_changed)	
	Signalbus.food_talked.connect(_on_food_talked)
	Signalbus.combo_changed.connect(_on_combo_changed)
	
	if guide != null:
		guide.visible = false
		guide.modulate.a = 0.0
	
	if combo_label != null:
		combo_label.visible = false
		combo_label.text = "x1.0"
		combo_label.scale = Vector2.ONE
	
	if finish_hint_label != null:
		finish_hint_label.visible = false
	
	if dialogues_label != null:
		dialogues_label.visible = false
		dialogues_label.text = ""
	
	_update_text_bar_visibility()

	if rpm_slider != null:
		rpm_slider.min_value = 0
		rpm_slider.max_value = 180
		rpm_slider.step = 10
		rpm_slider.value = 90 
		if not rpm_slider.value_changed.is_connected(_on_rpm_changed):
			rpm_slider.value_changed.connect(_on_rpm_changed)
		_update_rpm_label(rpm_slider.value)
		_emit_microwave_settings()
	
	# Configure Wattage slider
	if wattage_slider != null:
		wattage_slider.min_value = 0
		wattage_slider.max_value = 200
		wattage_slider.step = 10
		wattage_slider.value = 100  # Default wattage
		if not wattage_slider.value_changed.is_connected(_on_wattage_changed):
			wattage_slider.value_changed.connect(_on_wattage_changed)
		_update_wattage_label(wattage_slider.value)
		_emit_microwave_settings()

func _process(_delta: float) -> void:
	if Global.score != last_displayed_score:
		_update_score(Global.score)
	if Global.time_remaining != last_displayed_seconds:
		_update_time(Global.time_remaining)

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
	if finish_hint_label == null:
		return
	finish_hint_label.visible = active
	_update_text_bar_visibility()

func _on_rpm_changed(value: float) -> void:
	_update_rpm_label(value)
	_emit_microwave_settings()

func _on_wattage_changed(value: float) -> void:
	_update_wattage_label(value)
	_emit_microwave_settings()

func _emit_microwave_settings() -> void:
	var rpm: float = rpm_slider.value if rpm_slider != null else 90.0
	var wattage: int = int(wattage_slider.value) if wattage_slider != null else 100
	Signalbus.microwave_settings_changed.emit(rpm, wattage)

func _update_rpm_label(value: float) -> void:
	if rpm_label != null:
		rpm_label.text = "%.0f RPM" % value

func _update_wattage_label(value: float) -> void:
	if wattage_label != null:
		wattage_label.text = "%.0f W" % value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("guide"):
		_fade_in_guide()
		Signalbus.guide_mode_changed.emit(true)
	elif event.is_action_released("guide"):
		_fade_out_guide()
		Signalbus.guide_mode_changed.emit(false)

func _fade_in_guide() -> void:
	if guide == null:
		return
	
	# Stop any existing fade tween
	if _guide_fade_tween != null:
		_guide_fade_tween.kill()
	
	guide.visible = true
	guide.modulate.a = 0.0
	
	_guide_fade_tween = create_tween()
	_guide_fade_tween.tween_property(guide, "modulate:a", 1.0, fade_in_duration)

func _fade_out_guide() -> void:
	if guide == null:
		return
	
	# Stop any existing fade tween
	if _guide_fade_tween != null:
		_guide_fade_tween.kill()
	
	_guide_fade_tween = create_tween()
	_guide_fade_tween.tween_property(guide, "modulate:a", 0.0, fade_out_duration)
	_guide_fade_tween.tween_callback(func(): guide.visible = false)

func _on_food_talked(text: String) -> void:
	if dialogues_label == null:
		return
	dialogues_label.text = text
	dialogues_label.visible = text != ""
	_update_text_bar_visibility()

func _update_text_bar_visibility() -> void:
	if text_bar == null:
		return
	var has_dialogue: bool = dialogues_label != null and dialogues_label.visible and dialogues_label.text.strip_edges() != ""
	var has_finish_hint: bool = finish_hint_label != null and finish_hint_label.visible
	text_bar.visible = has_dialogue or has_finish_hint

func _on_combo_changed(streak: int, multiplier: float) -> void:
	if combo_label == null:
		return
	var should_show: bool = multiplier > 1.0
	combo_label.visible = should_show
	if should_show:
		combo_label.text = "x%.1f" % multiplier
		if streak > _combo_last_streak:
			_bounce_combo_label()
			AudioManager.play_sfx(load("res://assets/audio/sfx/combo.mp3"))

	_combo_last_streak = (streak if should_show else 0)

func _bounce_combo_label() -> void:
	if combo_label == null:
		return
	if _combo_tween != null:
		_combo_tween.kill()
	combo_label.scale = Vector2.ONE
	_combo_tween = create_tween()
	_combo_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.12)
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.18)
