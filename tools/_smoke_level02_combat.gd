extends Node

func _ready() -> void:
	var level := (load("res://scenes/levels/Level02.tscn") as PackedScene).instantiate() as Node3D
	add_child(level)
	await get_tree().process_frame
	var path := level.get_node("Path3D") as Path3D
	var spot := level.get_node("BuildSpot2") as BuildSpot
	var cannon_data := load("res://data/towers/Cannon.tres") as TowerData
	var grunt_data := load("res://data/enemies/Grunt.tres") as EnemyData
	spot.build(cannon_data)
	var cannon: Tower = spot.tower
	var progress_at_spot: float = path.curve.get_closest_offset(spot.global_position)
	var grunts: Array[Enemy] = []
	for index: int in 4:
		var grunt := grunt_data.scene.instantiate() as Enemy
		grunt.data = grunt_data
		path.add_child(grunt)
		grunt.progress = progress_at_spot + float(index) * 0.3
		grunts.append(grunt)
	for _frame: int in 60:
		await get_tree().physics_frame
	print("SMOKE level02_cannon_targeted=%s hp=%.1f/%.1f range=%.1f path_distance=%.1f" % [
		str(cannon.target != null),
		grunts[0].hp,
		grunts[0].max_hp,
		cannon.data.attack_range,
		cannon.global_position.distance_to(grunts[0].global_position),
	])
	var hero := level.get_node("Hero") as Hero
	var target: Vector3 = hero.best_meteor_target()
	var in_radius: int = 0
	for grunt: Enemy in grunts:
		if target.distance_squared_to(grunt.global_position) <= hero.meteor_radius * hero.meteor_radius:
			in_radius += 1
	hero.use_meteor(target)
	await get_tree().create_timer(hero.meteor_delay + 0.2).timeout
	var remaining: int = 0
	for grunt: Enemy in grunts:
		if is_instance_valid(grunt) and not grunt.is_dead:
			remaining += 1
	print("SMOKE level02_meteor_auto_target grouped=%d hit_or_killed=%s remaining=%d" % [
		in_radius,
		str(in_radius >= 3 and remaining == 0),
		remaining,
	])
	print("SMOKE done")
	get_tree().quit()
