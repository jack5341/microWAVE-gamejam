extends Node

signal ship_damaged(amount: float)
signal ship_repaired(amount: float)
signal ship_water_level_increased(amount: float)
signal ship_water_level_decreased(amount: float)

signal game_started
signal game_over
signal game_won

signal enemy_killed(enemy: Enemy)