extends Node
## Permanent cross-run bonuses purchased with crystal shards.

signal changed

const MAX_LEVEL: int = 3
const COSTS: Array[int] = [3, 6, 9]
const TRACKS: Array[StringName] = [&"vanguard", &"fortress", &"treasury"]
const TRACK_NAMES: Array[String] = ["Vanguard", "Fortress", "Treasury"]
const TRACK_DESCRIPTIONS: Array[String] = [
	"+10% tower & soldier damage per level",
	"+2 starting lives per level",
	"+40 starting gold per level",
]

func level_of(track: StringName) -> int:
	return clampi(SaveManager.get_upgrade(String(track)), 0, MAX_LEVEL)

func is_maxed(track: StringName) -> bool:
	return level_of(track) >= MAX_LEVEL

func next_cost(track: StringName) -> int:
	var level: int = level_of(track)
	return 0 if level >= MAX_LEVEL else COSTS[level]

func can_buy(track: StringName) -> bool:
	var cost: int = next_cost(track)
	return cost > 0 and SaveManager.get_shards() >= cost

func buy(track: StringName) -> bool:
	if not can_buy(track):
		return false
	var cost: int = next_cost(track)
	if not SaveManager.spend_shards(cost):
		return false
	SaveManager.set_upgrade(String(track), level_of(track) + 1)
	EventBus.upgrade_purchased.emit(track, level_of(track))
	changed.emit()
	return true

func tower_damage_multiplier() -> float:
	return 1.0 + 0.1 * float(level_of(&"vanguard"))

func bonus_start_lives() -> int:
	return 2 * level_of(&"fortress")

func bonus_start_gold() -> int:
	return 40 * level_of(&"treasury")
