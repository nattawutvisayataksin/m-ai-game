@tool
extends Node3D

@export var level_bounds: Rect2 = Rect2(-25.0, -25.0, 50.0, 50.0)

func _ready() -> void:
	if not Engine.is_editor_hint():
		_apply_runtime_defaults()

func _apply_runtime_defaults() -> void:
	var environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment and environment.environment:
		environment.environment.tonemap_exposure = 1.0
	var camera_rig := get_node_or_null("CameraRig")
	if camera_rig and camera_rig.has_method("set_level_bounds"):
		camera_rig.set_level_bounds(level_bounds)
