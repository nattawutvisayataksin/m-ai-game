class_name Projectile
extends Node3D
## Homing or arc projectile used by towers.

enum Motion { HOMING, ARC }

@export var motion: Motion = Motion.HOMING
@export var speed: float = 18.0
@export var arc_height: float = 3.0
@export var impact_vfx: PackedScene
@export var impact_scale: float = 1.0
@export var trail_color: Color = Color(1.0, 0.75, 0.3, 1.0)
@export var trail_length: float = 0.7

var _target: Enemy
var _data: TowerData
var _start: Vector3
var _target_pos: Vector3
var _t: float = 0.0
var _flight_time: float = 0.5
var _active: bool = false
var _trail: MeshInstance3D

func launch(from: Vector3, target: Enemy, tower_data: TowerData) -> void:
	global_position = from
	_start = from
	_target = target
	_data = tower_data
	_target_pos = target.global_position
	if motion == Motion.HOMING:
		_target_pos += Vector3.UP * 0.8
	_t = 0.0
	_flight_time = maxf(from.distance_to(_target_pos) / speed, 0.15)
	_active = true
	_ensure_trail()
	if _trail:
		_trail.visible = true

func _physics_process(delta: float) -> void:
	if not _active:
		return
	match motion:
		Motion.HOMING:
			if is_instance_valid(_target) and not _target.is_dead:
				_target_pos = _target.global_position + Vector3.UP * 0.8
			var direction := _target_pos - global_position
			var step: float = speed * delta
			if direction.length() <= step:
				_impact()
				return
			global_position += direction.normalized() * step
			if absf(direction.normalized().y) < 0.99:
				look_at(_target_pos, Vector3.UP, true)
		Motion.ARC:
			_t = minf(_t + delta / _flight_time, 1.0)
			var arc_position := _start.lerp(_target_pos, _t)
			arc_position.y += sin(_t * PI) * arc_height
			global_position = arc_position
			if _t >= 1.0:
				_impact()

func _impact() -> void:
	_active = false
	if _trail:
		_trail.visible = false
	if _data.aoe_radius > 0.0:
		var radius_squared: float = _data.aoe_radius * _data.aoe_radius
		for node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.is_dead:
				continue
			if enemy.data.is_flying and not _data.can_hit_flying:
				continue
			if enemy.global_position.distance_squared_to(global_position) <= radius_squared:
				_hit(enemy)
		EventBus.camera_shake.emit(0.12)
	elif is_instance_valid(_target) and not _target.is_dead:
		_hit(_target)
	if impact_vfx:
		var effect := impact_vfx.instantiate() as Node3D
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position
		effect.scale = Vector3.ONE * impact_scale
	ProjectilePool.release(self)

func _ensure_trail() -> void:
	if _trail != null:
		return
	_trail = MeshInstance3D.new()
	var ribbon := RibbonTrailMesh.new()
	ribbon.size = trail_length
	ribbon.sections = 2
	ribbon.section_length = trail_length * 0.5
	_trail.mesh = ribbon
	_trail.material_override = _trail_material()
	_trail.visible = false
	add_child(_trail)

func _trail_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _hit(enemy: Enemy) -> void:
	var damage: float = randf_range(_data.damage_min, _data.damage_max) * MetaProgression.tower_damage_multiplier()
	enemy.take_damage(damage, _data.damage_type)
	if _data.slow_amount > 0.0:
		enemy.apply_slow(1.0 - _data.slow_amount, _data.slow_duration)
	if _data.poison_dps > 0.0:
		enemy.apply_poison(_data.poison_dps, _data.poison_duration)
