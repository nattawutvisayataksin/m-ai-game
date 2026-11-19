extends Node
## Spawns small one-shot particle effects for gameplay events.

const COIN_BURST: PackedScene = preload("res://scenes/vfx/CoinBurst.tscn")
const METEOR_BLAST: PackedScene = preload("res://scenes/vfx/MeteorBlast.tscn")
const SPAWN_BURST: PackedScene = preload("res://scenes/vfx/MagicBurst.tscn")
const HEAL_BURST: PackedScene = preload("res://scenes/vfx/HealBurst.tscn")
const BUFF_BURST: PackedScene = preload("res://scenes/vfx/BuffBurst.tscn")

func _ready() -> void:
	EventBus.coin_pop.connect(_on_coin_pop)
	EventBus.meteor_impacted.connect(_on_meteor_impacted)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.heal_dealt.connect(_on_heal_dealt)
	EventBus.tower_disabled.connect(_on_tower_disabled)
	EventBus.enemy_buffed.connect(_on_enemy_buffed)

func _on_tower_disabled(world_position: Vector3, _duration: float) -> void:
	_spawn(SPAWN_BURST, world_position, 1.5)

func _on_enemy_buffed(world_position: Vector3) -> void:
	_spawn(BUFF_BURST, world_position, 0.9)

func _on_heal_dealt(world_position: Vector3, amount: float) -> void:
	var size: float = 0.8 + minf(amount / 40.0, 0.6)
	_spawn(HEAL_BURST, world_position, size)

func _on_enemy_spawned(enemy: Node3D) -> void:
	var spawned := enemy as Enemy
	if spawned == null or spawned.data == null:
		return
	var size: float = 2.0 if spawned.data.is_boss else 0.7
	_spawn(SPAWN_BURST, spawned.global_position + Vector3.UP * 0.4, size)

func _on_coin_pop(world_position: Vector3, amount: int) -> void:
	var size: float = 1.0 + minf(float(amount) / 12.0, 0.8)
	_spawn(COIN_BURST, world_position + Vector3.UP * 0.8, size)

func _on_meteor_impacted(world_position: Vector3) -> void:
	_spawn(METEOR_BLAST, world_position + Vector3.UP * 0.3, 1.6)

func _spawn(scene: PackedScene, world_position: Vector3, size: float) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var effect := scene.instantiate() as Node3D
	scene_root.add_child(effect)
	effect.global_position = world_position
	effect.scale = Vector3.ONE * size
