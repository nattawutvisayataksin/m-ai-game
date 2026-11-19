extends Node

func _ready() -> void:
	var level := (load("res://scenes/levels/Level04.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().process_frame

	var data := level.level_data as LevelData
	var spawner := level.get_node("WaveSpawner") as WaveSpawner
	var spot_count: int = 0
	for child in level.get_children():
		if child is BuildSpot:
			spot_count += 1
	var menu := level.get_node("RadialBuildMenu") as RadialBuildMenu

	print("SMOKE level id=%s name=%s hp_mult=%.2f" % [data.id, data.display_name, data.enemy_hp_multiplier])
	print("SMOKE paths=%d p0=%s p1=%s" % [
		spawner.paths.size(),
		spawner.paths[0].name,
		spawner.paths[1].name,
	])
	print("SMOKE waves=%d buildspots=%d towers=%d" % [
		spawner.total_waves(),
		spot_count,
		menu.tower_options.size(),
	])
	print("SMOKE start lives=%d/%d gold=%d" % [GameManager.lives, GameManager.max_lives, Economy.gold])

	for child in level.get_children():
		if child is BuildSpot:
			var nearest: float = 1e9
			for path_node in spawner.paths:
				var path := path_node as Path3D
				var length: float = path.curve.get_baked_length()
				var along: float = 0.0
				while along <= length:
					var point: Vector3 = path.curve.sample_baked(along)
					nearest = minf(nearest, child.global_position.distance_to(point))
					along += 0.25
			print("SMOKE spot %s nearest=%.1f" % [child.name, nearest])

	for index: int in spawner.total_waves():
		spawner.current_wave = index - 1
		print("SMOKE preview%d boss=%s :: %s" % [
			index + 1,
			str(data.waves[index].is_boss_wave),
			spawner.next_wave_summary(),
		])
	spawner.current_wave = -1

	spawner.call_next_wave()
	await get_tree().create_timer(2.5).timeout
	print("SMOKE wave1 pathA=%d pathB=%d" % [
		spawner.paths[0].get_child_count(),
		spawner.paths[1].get_child_count(),
	])

	var boss_spawned: bool = false
	for node in get_tree().get_nodes_in_group(&"enemies"):
		node.queue_free()
	await get_tree().process_frame
	spawner.waiting_for_next = true
	spawner.current_wave = data.waves.size() - 2
	spawner.call_next_wave()
	await get_tree().create_timer(0.6).timeout
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.data and enemy.data.is_boss:
			boss_spawned = true
			print("SMOKE boss path=%s hp=%.0f" % [enemy.get_parent().name, enemy.max_hp])
	print("SMOKE boss_spawned=%s" % str(boss_spawned))

	Engine.time_scale = 1.0
	level.queue_free()
	await get_tree().process_frame
	print("SMOKE done")
	get_tree().quit()
