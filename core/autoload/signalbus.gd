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