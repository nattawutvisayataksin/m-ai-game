extends Node
## Validates level scenery clearance and per-instance tower detection ranges.

const LEVELS: Array[String] = [
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
]

var _failures: int = 0

func _ready() -> void:
	for scene_path: String in LEVELS:
		await _check_level(scene_path)
	await _check_range_independence()
	print("SMOKE failures=%d" % _failures)
	print("SMOKE done")
	get_tree().quit()

func _check_level(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("cannot load %s" % scene_path)
		return
	var level := packed.instantiate()
	add_child(level)
	await get_tree().process_frame
	var scenery := level.get_node_or_null("Scenery")
	var spawner := level.get_node_or_null("WaveSpawner") as WaveSpawner
	var spots: Array[BuildSpot] = []
	for child: Node in level.get_children():
		var spot := child as BuildSpot
		if spot:
			spots.append(spot)
	var path_samples: Array[Vector3] = []
	if spawner:
		for path_node: Path3D in spawner.paths:
			var length: float = path_node.curve.get_baked_length()
			var along: float = 0.0
			while along <= length:
				path_samples.append(path_node.curve.sample_baked(along))
				along += 0.5
	var prop_count: int = 0
	var min_path: float = INF
	var min_spot: float = INF
	if scenery:
		for child: Node in scenery.get_children():
			var prop := child as Node3D
			if prop == null:
				continue
			prop_count += 1
			for point: Vector3 in path_samples:
				min_path = minf(min_path, prop.global_position.distance_to(point))
			for spot: BuildSpot in spots:
				min_spot = minf(min_spot, prop.global_position.distance_to(spot.global_position))
	print("SMOKE %s props=%d min_path=%.1f min_spot=%.1f" % [
		level.name,
		prop_count,
		min_path,
		min_spot,
	])
	if prop_count < 12:
		_fail("%s has too few props (%d)" % [level.name, prop_count])
	if min_path < 3.5:
		_fail("%s prop too close to lane (%.1f)" % [level.name, min_path])
	if min_spot < 4.0:
		_fail("%s prop too close to build spot (%.1f)" % [level.name, min_spot])
	level.queue_free()
	await get_tree().process_frame

func _check_range_independence() -> void:
	var base := load("res://data/towers/Archer.tres") as TowerData
	var upgraded := load("res://data/towers/Archer2.tres") as TowerData
	if base == null or upgraded == null or base.tower_scene == null or upgraded.tower_scene == null:
		_fail("archer data missing")
		return
	var first := base.tower_scene.instantiate() as Tower
	first.data = base
	add_child(first)
	var second := upgraded.tower_scene.instantiate() as Tower
	second.data = upgraded
	add_child(second)
	await get_tree().process_frame
	var first_node := first.get_node("DetectionArea/CollisionShape3D") as CollisionShape3D
	var second_node := second.get_node("DetectionArea/CollisionShape3D") as CollisionShape3D
	var first_shape := first_node.shape as SphereShape3D
	var second_shape := second_node.shape as SphereShape3D
	print("SMOKE range base=%.1f upgraded=%.1f shared=%s" % [
		first_shape.radius,
		second_shape.radius,
		str(first_shape == second_shape),
	])
	if not is_equal_approx(first_shape.radius, base.attack_range):
		_fail("base tower range mutated to %.1f" % first_shape.radius)
	if not is_equal_approx(second_shape.radius, upgraded.attack_range):
		_fail("upgraded tower range %.1f" % second_shape.radius)

	if first_shape == second_shape:
		_fail("tower instances share one detection shape")
	first.queue_free()
	second.queue_free()
	await get_tree().process_frame

func _fail(message: String) -> void:
	_failures += 1
	printerr("SMOKE FAIL %s" % message)
