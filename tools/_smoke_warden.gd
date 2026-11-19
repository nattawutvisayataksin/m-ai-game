extends Node

var _buff_events: int = 0

func _ready() -> void:
	EventBus.enemy_buffed.connect(_on_enemy_buffed)

	var root := Node3D.new()
	add_child(root)
	var path := Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3(0, 0, 0))
	curve.add_point(Vector3(30, 0, 0))
	path.curve = curve
	root.add_child(path)

	var grunt_data: EnemyData = load("res://data/enemies/Grunt.tres") as EnemyData
	var grunt := grunt_data.scene.instantiate() as Enemy
	grunt.data = grunt_data
	path.add_child(grunt)

	var warden_data: EnemyData = load("res://data/enemies/BannerWarden.tres") as EnemyData
	var warden := warden_data.scene.instantiate() as WardenEnemy
	warden.data = warden_data
	path.add_child(warden)

	var boss_data: EnemyData = load("res://data/enemies/BossGolem.tres") as EnemyData
	var boss := boss_data.scene.instantiate() as Enemy
	boss.data = boss_data
	path.add_child(boss)
	await get_tree().process_frame

	grunt.progress = 5.0
	warden.progress = 9.0
	boss.progress = 11.0
	grunt.speed_multiplier = 0.0
	warden.speed_multiplier = 0.0
	boss.speed_multiplier = 0.0
	await get_tree().create_timer(1.2).timeout

	print("SMOKE warden name=%s hp=%.0f radius=%.1f armor_buff=%.2f" % [
		warden.data.display_name,
		warden.max_hp,
		warden.aura_radius,
		warden.aura_armor,
	])
	print("SMOKE buffed armor=%.2f speed=%.2f events=%d ring=%s" % [
		grunt.bonus_armor,
		grunt.bonus_speed_multiplier,
		_buff_events,
		str(warden._aura_ring != null),
	])
	print("SMOKE boss_excluded armor=%.2f speed=%.2f" % [
		boss.bonus_armor,
		boss.bonus_speed_multiplier,
	])

	var before: float = grunt.hp
	grunt.take_damage(20.0, TowerData.DamageType.PHYSICAL)
	print("SMOKE damage_buffed %.1f->%.1f drop=%.1f" % [before, grunt.hp, before - grunt.hp])

	warden.take_damage(warden.max_hp * 2.0, TowerData.DamageType.TRUE)
	await get_tree().create_timer(1.6).timeout
	var before2: float = grunt.hp
	grunt.take_damage(20.0, TowerData.DamageType.PHYSICAL)
	print("SMOKE buff_expired armor=%.2f speed=%.2f drop=%.1f" % [
		grunt.bonus_armor,
		grunt.bonus_speed_multiplier,
		before2 - grunt.hp,
	])
	print("SMOKE done")
	get_tree().quit()

func _on_enemy_buffed(_world_position: Vector3) -> void:
	_buff_events += 1
