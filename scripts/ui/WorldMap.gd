class_name WorldMap
extends Control

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/SettingsPanel.tscn")
const BLESSINGS_SCENE: PackedScene = preload("res://scenes/ui/BlessingsPanel.tscn")

@export var level_ids: Array[StringName] = [&"level_01", &"level_02", &"level_03", &"level_04"]
@export var level_names: Array[String] = ["The Meadow", "Crystal Pass", "Bastion Gate", "Crystal Crossroads"]
@export var level_scene_paths: Array[String] = [
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
]
@export var previous_level_ids: Array[StringName] = [&"", &"level_01", &"level_02", &"level_03"]

@onready var level_buttons: Array[Button] = [$Level1, $Level2, $Level3, $Level4]
@onready var status_label: Label = $Status
@onready var settings_button: Button = $Settings
@onready var blessings_button: Button = $Blessings
@onready var shards_label: Label = $Shards
@onready var progress_label: Label = $Progress

var _settings: SettingsPanel
var _blessings: BlessingsPanel

func _ready() -> void:
	for index: int in level_buttons.size():
		level_buttons[index].pressed.connect(_on_level_pressed.bind(index))
	settings_button.pressed.connect(_open_settings)
	blessings_button.pressed.connect(_open_blessings)
	_settings = SETTINGS_SCENE.instantiate() as SettingsPanel
	add_child(_settings)
	_blessings = BLESSINGS_SCENE.instantiate() as BlessingsPanel
	add_child(_blessings)
	_blessings.closed.connect(_refresh_levels)
	MetaProgression.changed.connect(_refresh_shards)
	_refresh_levels()
	_refresh_shards()

func _open_settings() -> void:
	if _settings:
		_settings.open()

func _open_blessings() -> void:
	if _blessings:
		_blessings.open()

func _refresh_shards() -> void:
	shards_label.text = "Crystal Shards: %d" % SaveManager.get_shards()

func _refresh_levels() -> void:
	for index: int in level_buttons.size():
		if index >= level_ids.size():
			level_buttons[index].visible = false
			continue
		var level_id: String = String(level_ids[index])
		var previous_id: String = String(previous_level_ids[index]) if index < previous_level_ids.size() else ""
		var scene_path: String = level_scene_paths[index] if index < level_scene_paths.size() else ""
		var available: bool = scene_path != "" and ResourceLoader.exists(scene_path)
		var unlocked: bool = SaveManager.is_level_unlocked(level_id, previous_id)
		var stars: int = SaveManager.get_stars(level_id)
		var display_name: String = level_names[index] if index < level_names.size() else level_id
		var state_text: String = _stars_text(stars) if unlocked else "Locked"
		if not available:
			state_text = "Coming Soon"
		level_buttons[index].visible = true
		level_buttons[index].disabled = not unlocked or not available
		level_buttons[index].text = "%s\n%s" % [display_name, state_text]
	_update_progress()

func _update_progress() -> void:
	var total: int = 0
	var cleared: int = 0
	for index: int in level_ids.size():
		var stars: int = SaveManager.get_stars(String(level_ids[index]))
		total += stars
		if stars > 0:
			cleared += 1
	progress_label.text = "Total stars: %d / %d    Levels cleared: %d / %d" % [
		total,
		level_ids.size() * 3,
		cleared,
		level_ids.size(),
	]
	if cleared == level_ids.size():
		progress_label.text = "Campaign complete!    Total stars: %d / %d" % [total, level_ids.size() * 3]

func _on_level_pressed(index: int) -> void:
	if index >= level_ids.size() or index >= level_scene_paths.size():
		return
	var level_id: String = String(level_ids[index])
	var previous_id: String = String(previous_level_ids[index]) if index < previous_level_ids.size() else ""
	if not SaveManager.is_level_unlocked(level_id, previous_id):
		return
	var scene_path: String = level_scene_paths[index]
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		var display_name: String = level_names[index] if index < level_names.size() else level_id
		status_label.text = "%s is coming soon" % display_name
		return
	SaveManager.current_level_id = level_id
	get_tree().change_scene_to_file(scene_path)

func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(3 - stars)
