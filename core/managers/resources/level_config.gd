class_name LevelConfig extends Resource

@export var id: StringName = &"level_1"
@export var display_name: String = "Level 1"
@export var rounds: Array[RoundConfig] = []

# Global pacing defaults (GameManager can honor these)
@export var inter_wave_delay: float = 2.0
@export var inter_round_delay: float = 4.0