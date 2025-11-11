class_name RoundConfig extends Resource

@export var waves: Array[WaveConfig] = []
@export var win_condition: StringName = &"kill_all" # or &"survive_time"
@export var survive_time: float = 0.0               # used if win_condition == "survive_time"