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
	var build_spots: Array[Node] = find_children("BuildSpot*", "BuildSpot", true, false)
	if level_data.starting_build_spots > 0:
		for node: Node in build_spots:
			var locked_spot := node as BuildSpot
			if locked_spot:
				locked_spot.set_unlocked(false)
	for index: int in mini(level_data.starting_build_spots, build_spots.size()):
		var spot := build_spots[index] as BuildSpot
		if spot:
			spot.set_unlocked(true)
	if level_data.id == &"level_01":
		EventBus.wave_started.connect(_on_wave_started)
	var camera := get_node_or_null("CameraRig")
	if camera and camera.has_method("set_level_bounds"):
		camera.set_level_bounds(camera_bounds)
	var landmark := get_node_or_null("CrystalBastion") as Node3D
	if landmark:
		landmark.scale = Vector3.ONE * 0.92
	SaveManager.current_level_id = String(level_data.id)
	GameManager.start_level(level_data)

func _on_wave_started(wave_index: int) -> void:
	var spots_to_unlock: Array[String] = []
	if wave_index == 1:
		spots_to_unlock = ["BuildSpot2", "BuildSpot3"]
	elif wave_index == 2:
		spots_to_unlock = ["BuildSpot4", "BuildSpot5"]
	for spot_name: String in spots_to_unlock:
		var spot := get_node_or_null(spot_name) as BuildSpot
		if spot:
			spot.set_unlocked(true)
