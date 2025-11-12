class_name RawFood extends Base

@export var time_to_cook: float = 10.0
@export var difficulty_to_cook: int = 1
@export var humor_level: int = 1
@export var dialogue_lines: Array[String] = []
@export var burn_temprature: int = 100
@export var raw_temprature: int = 0
@export var food: Food = null
@export var blue_rate: float = 0.6
@export var green_rate: float = 1.0
@export var red_rate: float = 1.7
@export var burn_time_threshold: float = 2.5
@export var base_points: int = 10
