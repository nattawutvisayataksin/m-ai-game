extends Node

func _ready() -> void:
	for path: String in ["res://scenes/towers/BasicTower.tscn", "res://scenes/towers/CannonTower.tscn", "res://scenes/towers/MageTower.tscn", "res://scenes/towers/Barracks.tscn"]:
		var tower := (load(path) as PackedScene).instantiate() as Tower
		add_child(tower)
		await get_tree().process_frame
		print("SMOKE %s turret=%s muzzle=%s node_turret=%s" % [
			tower.name,
			str(tower.turret),
			str(tower.muzzle),
			str(tower.get_node_or_null("Turret")),
		])
		tower.queue_free()
		await get_tree().process_frame
	get_tree().quit()
