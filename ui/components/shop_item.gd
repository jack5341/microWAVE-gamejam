extends PanelContainer

@export_category("Shop Item")
@export var decoration_name: String = ""
@export var price: int = 0
@export var description: String = ""

@onready var name_label: Label = $MarginContainer/VBoxContainer/Name
@onready var price_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Price
@onready var description_label: Label = $MarginContainer/VBoxContainer/Description
@onready var buy_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/BuyButton

var is_purchased: bool = false
var _on_buy_callback: Callable

func _ready() -> void:
	_update_display()
	if buy_button != null:
		buy_button.pressed.connect(_on_buy_button_pressed)

func _update_display() -> void:
	if name_label != null and decoration_name != "":
		name_label.text = decoration_name
	if price_label != null:
		price_label.text = "Coin:  %d" % price
	if description_label != null and description != "":
		description_label.text = description
	_update_button_state()

func _update_button_state() -> void:
	if buy_button == null:
		return
	if is_purchased:
		buy_button.text = "Owned"
		buy_button.disabled = true
	else:
		buy_button.text = "Buy"
		buy_button.disabled = (Global.score < price)

func set_purchased(purchased: bool) -> void:
	is_purchased = purchased
	_update_button_state()

func set_buy_callback(callback: Callable) -> void:
	_on_buy_callback = callback

func _on_buy_button_pressed() -> void:
	if is_purchased:
		return
	if Global.score < price:
		return
	if _on_buy_callback.is_valid():
		_on_buy_callback.call(decoration_name, price)

func _process(_delta: float) -> void:
	# Update button state based on current score
	if not is_purchased:
		_update_button_state()
