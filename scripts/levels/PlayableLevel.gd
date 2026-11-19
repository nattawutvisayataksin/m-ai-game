class_name PlayableLevel
extends Node3D

@export var level_data: LevelData
@export var camera_rig: NodePath = NodePath("CameraRig")

func _ready() -> void:
	if level_data == null:
		push_error("PlayableLevel requires LevelData.")
		return
	var spawner := get_node_or_null("WaveSpawner") as WaveSpawner
	if spawner:
		spawner.level_data = level_data
	var camera := get_node_or_null(camera_rig)
	if camera and camera.has_method("set_level_bounds"):
		camera.set_level_bounds(Rect2(-25.0, -25.0, 50.0, 50.0))
