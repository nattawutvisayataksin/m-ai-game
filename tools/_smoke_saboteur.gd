extends Node

var _disabled_events: int = 0
var _fired_events: int = 0

func _ready() -> void:
	EventBus.tower_disabled.connect(_on_tower_disabled)
	EventBus.tower_fired.connect(_on_tower_fired)

	var root := Node3D.new()
	add_child(root)

	var path := Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3(0, 0, 0))
	curve.add_point(Vector3(12, 0, 0))
	path.curve = curve
	root.add_child(path)

	var tower_data: TowerData = load("res://data/towers/Archer.tres") as TowerData
	var tower := tower_data.tower_scene.instantiate() as Tower
	tower.data = tower_data
	root.add_child(tower)
	tower.global_position = Vector3(5, 0, 0)
	await get_tree().process_frame
	print("SMOKE tower group=%s disabled=%s" % [
		str(tower.is_in_group(&"towers")),
		str(tower.is_disabled),
	])

	var saboteur_data: EnemyData = load("res://data/enemies/CrystalSaboteur.tres") as EnemyData
	var saboteur := saboteur_data.scene.instantiate() as SaboteurEnemy
	saboteur.data = saboteur_data
	path.add_child(saboteur)
	await get_tree().process_frame
	saboteur.progress = 3.0
	saboteur.speed_multiplier = 0.0
	await get_tree().process_frame
	print("SMOKE saboteur name=%s hp=%.0f speed=%.1f radius=%.1f" % [
		saboteur.data.display_name,
		saboteur.max_hp,
		saboteur.data.speed,
		saboteur.disable_radius,
	])

	saboteur._cooldown = 0.05
	await get_tree().create_timer(1.2).timeout
	var label_text: String = tower._status_label.text if tower._status_label else "-"
	var label_visible: bool = tower._status_label.visible if tower._status_label else false
	print("SMOKE disabled=%s events=%d duration=%.1f label=%s visible=%s" % [
		str(tower.is_disabled),
		_disabled_events,
		saboteur.disable_duration,
		label_text,
		str(label_visible),
	])

	var fired_before: int = _fired_events
	await get_tree().create_timer(1.0).timeout
	print("SMOKE fired_while_disabled=%d" % (_fired_events - fired_before))

	await get_tree().create_timer(saboteur.disable_duration).timeout
	print("SMOKE reenabled=%s label_visible=%s" % [
		str(not tower.is_disabled),
		str(tower._status_label.visible if tower._status_label else false),
	])

	var fired_after: int = _fired_events
	await get_tree().create_timer(1.0).timeout
	print("SMOKE fired_after_enable=%d" % (_fired_events - fired_after))

	saboteur.take_damage(saboteur.max_hp * 2.0, TowerData.DamageType.TRUE)
	await get_tree().process_frame
	print("SMOKE saboteur_dead=%s" % str(not is_instance_valid(saboteur) or saboteur.is_dead))
	print("SMOKE done")
	get_tree().quit()

func _on_tower_disabled(_world_position: Vector3, _duration: float) -> void:
	_disabled_events += 1

func _on_tower_fired(_world_position: Vector3) -> void:
	_fired_events += 1
