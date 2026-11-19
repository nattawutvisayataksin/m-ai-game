extends Node

var _heal_events: int = 0
var _heal_total: float = 0.0

func _ready() -> void:
	EventBus.heal_dealt.connect(_on_heal_dealt)
	var level := (load("res://scenes/levels/Level02.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().process_frame
	var path := level.get_node("Path3D") as Path3D

	var grunt_data: EnemyData = load("res://data/enemies/Grunt.tres") as EnemyData
	var grunt := grunt_data.scene.instantiate() as Enemy
	grunt.data = grunt_data
	path.add_child(grunt)

	var wisp_data: EnemyData = load("res://data/enemies/CrystalWisp.tres") as EnemyData
	var wisp := wisp_data.scene.instantiate() as HealerEnemy
	wisp.data = wisp_data
	path.add_child(wisp)
	await get_tree().process_frame
	grunt.progress = 4.0
	wisp.progress = 5.0
	grunt.take_damage(grunt.max_hp * 0.5, TowerData.DamageType.TRUE)
	var before: float = grunt.hp
	await get_tree().create_timer(5.4).timeout
	print("SMOKE wisp name=%s flying=%s hp=%.0f/%.0f radius=%.1f interval=%.1f" % [
		wisp.data.display_name,
		str(wisp.data.is_flying),
		wisp.hp,
		wisp.max_hp,
		wisp.heal_radius,
		wisp.heal_interval,
	])
	print("SMOKE heal before=%.0f after=%.0f events=%d total=%.0f" % [
		before,
		grunt.hp,
		_heal_events,
		_heal_total,
	])
	wisp.take_damage(wisp.max_hp * 2.0, TowerData.DamageType.TRUE)
	await get_tree().create_timer(1.2).timeout
	print("SMOKE wisp_dead=%s" % str(not is_instance_valid(wisp) or wisp.is_dead))
	print("SMOKE done")
	get_tree().quit()

func _on_heal_dealt(_world_position: Vector3, amount: float) -> void:
	_heal_events += 1
	_heal_total += amount
