extends Node

@warning_ignore("UNUSED_SIGNAL")
signal food_cooked(food: Food)
@warning_ignore("UNUSED_SIGNAL")
signal cooking_cycle_completed()
@warning_ignore("UNUSED_SIGNAL")
signal score_changed(score: int)
@warning_ignore("UNUSED_SIGNAL")
signal time_remaining_changed(seconds: int)
@warning_ignore("UNUSED_SIGNAL")
signal request_raw_food_cook(raw: RawFood)
@warning_ignore("UNUSED_SIGNAL")
signal waiting_for_finish_changed(active: bool)
@warning_ignore("UNUSED_SIGNAL")
signal balance_zone_changed(zone: int) # -1=blue, 0=green, 1=red
@warning_ignore("UNUSED_SIGNAL")
signal set_balance_bar_difficulty(level: int) # 1=EASY, 2=MEDIUM, 3=HARD

@warning_ignore("UNUSED_SIGNAL")
signal change_rpm_microwave(rpm: float)
@warning_ignore("UNUSED_SIGNAL")
signal change_power_microwave(wattage: int)
@warning_ignore("UNUSED_SIGNAL")
signal change_temperature_microwave(temperature: int)

@warning_ignore("UNUSED_SIGNAL")
signal combo_changed(streak: int, multiplier: float)

@warning_ignore("UNUSED_SIGNAL")
signal food_talked(string: String)

@warning_ignore("UNUSED_SIGNAL")
signal guide_mode_changed(active: bool)

@warning_ignore("UNUSED_SIGNAL")
signal red_zone_space_pressed()
@warning_ignore("UNUSED_SIGNAL")
signal blue_zone_space_pressed()