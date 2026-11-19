extends Node

func _ready() -> void:
	var level := (load("res://scenes/levels/Level01.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().process_frame
	var menu := level.get_node("RadialBuildMenu") as RadialBuildMenu
	var spot := level.get_node("BuildSpot1") as BuildSpot
	menu._on_spot_clicked(spot)
	await get_tree().process_frame
	var texts: Array[String] = []
	for index: int in 4:
		var button := menu.get_node("Panel/VBox/Tower%d" % (index + 1)) as Button
		texts.append("%s@y%.0f" % [button.text.replace("\n", " "), button.global_position.y])
	print("SMOKE menu options=%d panel_h=%.0f %s" % [
		menu.tower_options.size(),
		(menu.panel as Control).size.y,
		" | ".join(texts),
	])
	menu._build_pressed(2)
	await get_tree().process_frame
	var cannon := spot.tower
	print("SMOKE cannon built=%s name=%s turret=%s muzzle=%s range=%.1f aoe=%.1f" % [
		str(cannon != null),
		cannon.data.display_name if cannon else "none",
		str(cannon.turret != null) if cannon else "false",
		str(cannon.muzzle != null) if cannon else "false",
		cannon.data.attack_range if cannon else 0.0,
		cannon.data.aoe_radius if cannon else 0.0,
	])
	EventBus.tower_selected.emit(cannon)
	await get_tree().process_frame
	print("SMOKE cannon upgrade=%s" % menu.upgrade_button.text)
	menu.visible = false
	var spot2 := level.get_node("BuildSpot2") as BuildSpot
	var barracks_data: TowerData = load("res://data/towers/Barracks.tres") as TowerData
	print("SMOKE barracks build=%s name=%s upgrades=%d" % [
		str(spot2.build(barracks_data)),
		spot2.tower.data.display_name if spot2.tower else "none",
		spot2.tower.data.upgrade_to.size() if spot2.tower and spot2.tower.data else 0,
	])
	EventBus.tower_selected.emit(spot2.tower)
	await get_tree().process_frame
	print("SMOKE barracks upgrade=%s" % menu.upgrade_button.text)
	menu.visible = false
	for path: String in ["res://scenes/projectiles/Arrow.tscn", "res://scenes/projectiles/Cannonball.tscn", "res://scenes/projectiles/MagicBolt.tscn"]:
		var projectile := (load(path) as PackedScene).instantiate() as Projectile
		print("SMOKE projectile %s mesh=%s vfx=%s scale=%.2f" % [
			projectile.name,
			str(projectile.get_child_count() > 0),
			str(projectile.impact_vfx != null),
			projectile.impact_scale,
		])
		projectile.free()
	var spawner := level.get_node("WaveSpawner") as WaveSpawner
	spawner.start_next_wave()
	await get_tree().create_timer(0.8).timeout
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	if not enemies.is_empty():
		var enemy := enemies[0] as Enemy
		enemy.progress = 20.0
		var start_hp: float = enemy.hp
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(enemy):
			print("SMOKE cannon fired hp=%.1f/%.1f slowed=%s target=%s" % [
				enemy.hp,
				start_hp,
				str(enemy._slow_time > 0.0),
				str(cannon.target == enemy),
			])
		else:
			print("SMOKE cannon killed target start_hp=%.1f" % start_hp)
	else:
		print("SMOKE no_enemy")
	print("SMOKE done")
	get_tree().quit()
