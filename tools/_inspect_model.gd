extends Node

const MODELS: Array[String] = [
	"res://assets/models/generated/archer_tower.glb",
	"res://assets/models/generated/enemy_basic.glb",
	"res://assets/models/generated/hero_basic.glb",
	"res://assets/models/generated/stylized_pine.glb",
	"res://assets/models/generated/stylized_broadleaf.glb",
	"res://assets/models/generated/stylized_rock_spire.glb",
]

func _ready() -> void:
	for path: String in MODELS:
		var packed := load(path) as PackedScene
		if packed == null:
			print("SMOKE %s MISSING" % path.get_file())
			continue
		var scene := packed.instantiate()
		add_child(scene)
		await get_tree().process_frame
		var combined := AABB()
		var has_box: bool = false
		for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := node as MeshInstance3D
			var box: AABB = mesh_node.global_transform * mesh_node.get_aabb()
			combined = box if not has_box else combined.merge(box)
			has_box = true
		print("SMOKE %s pos=%s size=%s" % [path.get_file(), combined.position, combined.size])
		scene.queue_free()
		await get_tree().process_frame
	get_tree().quit()
