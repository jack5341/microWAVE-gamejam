class_name WaveConfig extends Resource

@export var enemy_scene: PackedScene
@export var count: int = 5
@export var spawn_interval: float = 0.5
@export var start_delay: float = 0.0
@export var spawn_group: StringName = &"enemy_spawn_sea" # group of sea spawn points