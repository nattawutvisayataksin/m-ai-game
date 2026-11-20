class_name FreeBuildController
extends Node3D
## Optional Ctrl-click tower placement on valid ground.

const BUILD_SPOT_SCENE: PackedScene = preload("res://scenes/world/BuildSpot.tscn")

@export var tower_options: Array[TowerData] = []
@export var minimum_path_clearance: float = 3.0
@export var minimum_tower_clearance: float = 3.0
@export var ground_mask: int = 1

func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.ctrl_pressed:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(mouse.position)
	var end := origin + camera.project_ray_normal(mouse.position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = ground_mask
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.has("position"):
		return
	var position := hit["position"] as Vector3
	if not _valid_position(position):
		return
	var spot := BUILD_SPOT_SCENE.instantiate() as BuildSpot
	spot.position = position
	spot.is_unlocked = true
	add_child(spot)
	spot.set_unlocked(true)
	EventBus.build_spot_clicked.emit(spot)
	get_viewport().set_input_as_handled()

func _valid_position(position: Vector3) -> bool:
	var path := get_parent().get_node_or_null("Path3D") as Path3D
	if path != null and path.curve != null:
		var nearest := path.curve.get_closest_point(position)
		if nearest.distance_to(position) < minimum_path_clearance:
			return false
	for node: Node in get_tree().get_nodes_in_group(&"towers"):
		var tower := node as Node3D
		if tower != null and tower.global_position.distance_to(position) < minimum_tower_clearance:
			return false
	return true
