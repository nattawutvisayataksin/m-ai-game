extends Node3D

@export var level_data: LevelData
@export var tower_options: Array[TowerData] = []
@export var camera_bounds: Rect2 = Rect2(-25.0, -25.0, 50.0, 50.0)

func _ready() -> void:
	if level_data == null:
		push_error("Playable level requires LevelData.")
		return
	var spawner := get_node_or_null("WaveSpawner") as WaveSpawner
	if spawner:
		spawner.level_data = level_data
	var menu := get_node_or_null("RadialBuildMenu") as RadialBuildMenu
	if menu:
		menu.tower_options = tower_options
	var camera := get_node_or_null("CameraRig")
	if camera and camera.has_method("set_level_bounds"):
		camera.set_level_bounds(camera_bounds)
	SaveManager.current_level_id = String(level_data.id)
	GameManager.start_level(level_data)
