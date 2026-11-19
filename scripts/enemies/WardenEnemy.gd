class_name WardenEnemy
extends Enemy
## Elite support: projects an aura that grants nearby allies armour and speed.

@export var aura_radius: float = 8.0
@export var aura_armor: float = 0.15
@export var aura_speed_multiplier: float = 1.2
@export var aura_tick: float = 0.5
@export var aura_duration: float = 0.8
@export var sparkle_interval: float = 1.0

var _aura_timer: float = 0.0
var _sparkle_timer: float = 0.0
var _sparkle_index: int = 0
var _buffed: Array[Enemy] = []
var _aura_ring: MeshInstance3D

func _ready() -> void:
	super._ready()
	_aura_timer = aura_tick
	_sparkle_timer = sparkle_interval
	_build_aura_ring()

func _process(delta: float) -> void:
	if is_dead:
		return
	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = aura_tick
		_apply_aura()
	_sparkle_timer -= delta
	if _sparkle_timer <= 0.0 and not _buffed.is_empty():
		_sparkle_timer = sparkle_interval
		_sparkle_index = (_sparkle_index + 1) % _buffed.size()
		var ally: Enemy = _buffed[_sparkle_index]
		if is_instance_valid(ally) and not ally.is_dead:
			EventBus.enemy_buffed.emit(ally.global_position + Vector3.UP * 1.2)
	if _aura_ring and _aura_ring.material_override is StandardMaterial3D:
		var material := _aura_ring.material_override as StandardMaterial3D
		material.albedo_color.a = 0.16 + 0.07 * sin(Time.get_ticks_msec() * 0.003)

func _apply_aura() -> void:
	_buffed.clear()
	var radius_squared: float = aura_radius * aura_radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var ally := node as Enemy
		if ally == null or ally == self or ally.is_dead:
			continue
		if ally.data and ally.data.is_boss:
			continue
		if ally.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		ally.apply_buff(aura_armor, aura_speed_multiplier, aura_duration)
		_buffed.append(ally)

func _build_aura_ring() -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(aura_radius - 0.18, 0.1)
	mesh.outer_radius = aura_radius
	mesh.rings = 56
	mesh.ring_segments = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.78, 0.35, 0.22)
	_aura_ring = MeshInstance3D.new()
	_aura_ring.mesh = mesh
	_aura_ring.material_override = material
	_aura_ring.position.y = 0.08
	add_child(_aura_ring)
