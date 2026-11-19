extends Node
## Reuses projectile nodes instead of instantiating/freeing every shot.

var _pools: Dictionary = {}

func acquire(scene: PackedScene) -> Node3D:
	var pool: Array = _pools.get_or_add(scene, [])
	var node: Node3D
	if pool.is_empty():
		node = scene.instantiate() as Node3D
		node.set_meta(&"pool_scene", scene)
		add_child(node)
	else:
		node = pool.pop_back()
	node.visible = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
	return node

func release(node: Node3D) -> void:
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	var scene: PackedScene = node.get_meta(&"pool_scene")
	_pools[scene].append(node)

func clear_all() -> void:
	for child in get_children():
		child.queue_free()
	_pools.clear()
