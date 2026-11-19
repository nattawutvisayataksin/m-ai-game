extends Node

func _ready() -> void:
	var level := (load("res://scenes/levels/Level03.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().process_frame
	var spawner := level.get_node("WaveSpawner") as WaveSpawner
	print("SMOKE next_wave=%s" % spawner.next_wave_summary())
	var hud := level.get_node("GameHUD") as GameHUD
	var bar := hud.get_node("BossHealthBar") as BossHealthBar
	print("SMOKE bossbar_hidden=%s" % str(not bar.visible))

	var boss_data: EnemyData = load("res://data/enemies/BossGolem.tres") as EnemyData
	var boss := boss_data.scene.instantiate() as BossEnemy
	boss.data = boss_data
	(level.get_node("Path3D") as Path3D).add_child(boss)
	await get_tree().process_frame
	print("SMOKE boss_spawned=%s name=%s hp=%.0f/%.0f fill=%.0f" % [
		str(bar.visible),
		bar.name_label.text,
		boss.hp,
		boss.max_hp,
		bar.health_bar.value,
	])

	var hero := level.get_node("Hero") as Hero
	hero.global_position = boss.global_position + Vector3(1.5, 0.0, 0.0)
	hero.set_move_destination(hero.global_position)
	var hero_hp_before: float = hero.hp
	boss._slam_timer = 0.05
	await get_tree().create_timer(1.3).timeout
	print("SMOKE slam hero_hp=%.0f->%.0f slam_radius=%.1f windup=%.1f" % [
		hero_hp_before,
		hero.hp,
		boss.slam_radius,
		boss.slam_windup,
	])

	boss.take_damage(boss.max_hp * 0.4, TowerData.DamageType.TRUE)
	await get_tree().create_timer(0.4).timeout
	var enemies_after_summon: int = get_tree().get_nodes_in_group(&"enemies").size()
	print("SMOKE summon enemies=%d group_size=%d" % [enemies_after_summon, boss.summon_group_size])

	boss.take_damage(boss.max_hp * 0.15, TowerData.DamageType.TRUE)
	await get_tree().create_timer(0.2).timeout
	print("SMOKE phase2 active=%s speed=%.2f slam_interval=%.1f" % [
		str(boss._phase_two),
		boss.speed_multiplier,
		boss.slam_interval,
	])
	print("SMOKE boss_damaged fill=%.0f text=%s" % [bar.health_bar.value, bar.health_text.text])

	boss.take_damage(boss.max_hp * 2.0, TowerData.DamageType.TRUE)
	await get_tree().create_timer(1.6).timeout
	print("SMOKE boss_dead hidden=%s" % str(not bar.visible))

	var menu := level.get_node("RadialBuildMenu") as RadialBuildMenu
	var archer: TowerData = load("res://data/towers/Archer.tres") as TowerData
	print("SMOKE tooltip=%s" % menu._tower_tooltip(archer).replace("\n", " | "))
	print("SMOKE done")
	get_tree().quit()
