extends Control

@export_category("Guide Fade")
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.3

@onready var score_label: Label = $TopBar/VBoxContainer/HBoxContainer/Score
@onready var countdown_label: Label = $TopBar/VBoxContainer/HBoxContainer/Countdown
@onready var finish_hint_label: Label = $TextBar/FinishHint
@onready var dialogues_label: Label = $TextBar/Dialogues
@onready var text_bar: Panel = $TextBar

@onready var combo_label: Label = $ControlPanel/HBoxContainer/Control/ComboLabel

@onready var guide: CenterContainer = $Guide
@onready var guide_grid: GridContainer = $Guide/Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer

var last_displayed_score: int = -1
var last_displayed_seconds: int = -1
var _guide_fade_tween: Tween = null
var _combo_tween: Tween = null
var _combo_last_streak: int = 0

# Decoration data: name, price, description
var decoration_data: Array[Dictionary] = [
	{"name": "Rug", "price": 50, "description": "A cozy rug"},
	{"name": "Couch", "price": 100, "description": "Comfortable seating"},
	{"name": "Radio", "price": 75, "description": "Vintage radio"},
	{"name": "LightCable", "price": 30, "description": "Light cable"},
	{"name": "LightBulb", "price": 40, "description": "Bright light"},
	{"name": "Katana", "price": 200, "description": "Sharp blade"},
	{"name": "AK47", "price": 250, "description": "Powerful weapon"},
	{"name": "Billboard", "price": 150, "description": "Decorative sign"},
	{"name": "Fireplace", "price": 300, "description": "Warm fireplace"},
	{"name": "Rug2", "price": 60, "description": "Another rug"},
	{"name": "BearHeadMount", "price": 400, "description": "Trophy mount"},
	{"name": "Wine1", "price": 80, "description": "Fine wine"},
	{"name": "Wine2", "price": 80, "description": "Fine wine"},
	{"name": "Wine3", "price": 80, "description": "Fine wine"},
	{"name": "Glass", "price": 50, "description": "Elegant glass"},
	{"name": "Hamburger", "price": 120, "description": "Delicious burger"},
]

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
		_setup_shop()
	
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

func _setup_shop() -> void:
	if guide_grid == null:
		return
	
	# Clear existing items (keep food guide items if they exist, or clear all)
	# We'll replace the food guide with shop items
	for child in guide_grid.get_children():
		# Only remove shop items, keep food guide items if needed
		# Actually, let's replace all with shop items
		child.queue_free()
	
	# Load shop item scene
	var shop_item_scene: PackedScene = load("res://ui/components/shop_item.tscn")
	if shop_item_scene == null:
		return
	
	# Create shop items for each decoration
	for decoration in decoration_data:
		var item: Control = shop_item_scene.instantiate()
		if item == null:
			continue
		guide_grid.add_child(item)
		
		# Set decoration data
		item.decoration_name = decoration.name
		item.price = decoration.price
		item.description = decoration.description
		
		# Set purchase state
		item.set_purchased(Global.is_decoration_purchased(decoration.name))
		
		# Set buy callback
		item.set_buy_callback(_on_decoration_purchased)
		
		# Update display after node is ready (deferred to ensure @onready vars are set)
		item.call_deferred("_update_display")

func _on_decoration_purchased(decoration_name: String, price: int) -> void:
	if Global.score < price:
		return
	if Global.is_decoration_purchased(decoration_name):
		return
	
	# Deduct coins
	Global.score -= price
	Global.purchase_decoration(decoration_name)
	Signalbus.score_changed.emit(Global.score)
	
	# Update shop items
	_setup_shop()
	
	# Update decoration visibility in microwave
	_update_decoration_visibility()

func _update_decoration_visibility() -> void:
	# Find microwave in scene tree
	var microwave: Microwave = get_tree().get_first_node_in_group("microwave")
	if microwave == null:
		# Try to find it by searching the scene tree
		var root: Node = get_tree().root
		microwave = _find_microwave_in_tree(root)
	
	if microwave != null and microwave.has_method("_update_decoration_visibility"):
		microwave._update_decoration_visibility()

func _find_microwave_in_tree(node: Node) -> Microwave:
	if node is Microwave:
		return node
	for child in node.get_children():
		var result: Microwave = _find_microwave_in_tree(child)
		if result != null:
			return result
	return null
