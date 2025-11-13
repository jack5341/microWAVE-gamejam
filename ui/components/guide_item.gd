extends VBoxContainer

@export_category("Guide Item")
@export var name_text: String = ""
@export var label_1_text: String = ""
@export var label_2_text: String = ""
@export var label_3_text: String = ""

@onready var name_label: Label = $Name
@onready var label_1: Label = $Label1
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3

func _ready() -> void:
	if name_label != null and name_text != "":
		name_label.text = name_text
	if label_1 != null and label_1_text != "":
		label_1.text = label_1_text
	if label_2 != null and label_2_text != "":
		label_2.text = label_2_text
	if label_3 != null and label_3_text != "":
		label_3.text = label_3_text
