extends Node

const SAVE_PATH: String = "user://save.json"

var data: Dictionary = {
	"stars": {},
	"shards": 0,
	"upgrades": {"vanguard": 0, "fortress": 0, "treasury": 0},
	"settings": {"music": 0.8, "sfx": 0.8, "fullscreen": false, "language": "en"},
}
var current_level_id: String = ""

var default_data: Dictionary = {
	"stars": {},
	"shards": 0,
	"upgrades": {"vanguard": 0, "fortress": 0, "treasury": 0},
	"settings": {"music": 0.8, "sfx": 0.8, "fullscreen": false, "language": "en"},
}

func _ready() -> void:
	load_game()
	EventBus.level_won.connect(_on_level_won)

func get_stars(level_id: String) -> int:
	return int(data["stars"].get(level_id, 0))

func is_level_unlocked(_level_id: String, previous_level_id: String = "") -> bool:
	if previous_level_id == "":
		return true
	return get_stars(previous_level_id) > 0

func get_setting(key: StringName, fallback: Variant = null) -> Variant:
	return data["settings"].get(String(key), fallback)

func set_setting(key: StringName, value: Variant) -> void:
	data["settings"][String(key)] = value
	save_game()

func set_stars(level_id: String, stars: int) -> void:
	if stars > get_stars(level_id):
		data["stars"][level_id] = stars
		save_game()

func get_shards() -> int:
	return int(data.get("shards", 0))

func campaign_complete() -> bool:
	# Level 4 only unlocks after every earlier level is cleared, so its stars
	# are enough to prove the campaign is finished.
	return get_stars("level_04") > 0

func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	data["shards"] = get_shards() + amount
	save_game()

func spend_shards(amount: int) -> bool:
	if amount <= 0 or get_shards() < amount:
		return false
	data["shards"] = get_shards() - amount
	save_game()
	return true

func get_upgrade(track: String) -> int:
	var upgrades: Dictionary = data.get("upgrades", {})
	return int(upgrades.get(track, 0))

func set_upgrade(track: String, level: int) -> void:
	var upgrades: Dictionary = data.get("upgrades", {})
	upgrades[track] = maxi(level, 0)
	data["upgrades"] = upgrades
	save_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		data.merge(parsed, true)
	data["stars"] = data.get("stars", default_data["stars"])
	data["settings"] = default_data["settings"].merged(data.get("settings", {}), true)
	data["upgrades"] = default_data["upgrades"].merged(data.get("upgrades", {}), true)
	data["shards"] = int(data.get("shards", 0))

func _on_level_won(stars: int) -> void:
	if current_level_id == "":
		EventBus.shards_awarded.emit(0, get_shards())
		return
	var previous: int = get_stars(current_level_id)
	if stars <= previous:
		EventBus.shards_awarded.emit(0, get_shards())
		return
	data["stars"][current_level_id] = stars
	data["shards"] = get_shards() + stars
	save_game()
	EventBus.shards_awarded.emit(stars, get_shards())
