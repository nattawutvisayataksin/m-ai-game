class_name Tower
extends Node3D
## Base class for shooting towers.

enum TargetMode { FIRST, LAST, STRONGEST, CLOSEST }

@export var data: TowerData
@export var turret: Node3D
@export var muzzle: Marker3D
@export var turn_speed: float = 10.0
@export var fire_sound: AudioStream

@onready var detection_area: Area3D = $DetectionArea

var target_mode: TargetMode = TargetMode.FIRST
var target: Enemy
var total_spent: int = 0
var is_disabled: bool = false

var _cooldown: float = 0.0
var _retarget_timer: float = 0.0
var _range_ring: MeshInstance3D
var _status_label: Label3D
var _idle_time: float = 0.0
var _turret_base_y: float = 0.0

func _ready() -> void:
	add_to_group(&"towers")
	if turret == null:
		turret = get_node_or_null("Turret") as Node3D
	if turret != null:
		_turret_base_y = turret.position.y
	if muzzle == null and turret != null:
		muzzle = turret.get_node_or_null("Muzzle") as Marker3D
	if data == null:
		set_physics_process(false)
		return
	if detection_area:
		detection_area.collision_mask |= 2
	if detection_area and detection_area.get_child_count() > 0:
		var shape_node := detection_area.get_child(0) as CollisionShape3D
		var sphere := shape_node.shape as SphereShape3D if shape_node else null
		if sphere:
			# Scene sub-resources are shared by every instance of the same
			# PackedScene, so duplicate before applying per-tower range data.
			var own_sphere := sphere.duplicate() as SphereShape3D
			own_sphere.radius = data.attack_range
			shape_node.shape = own_sphere
	_build_range_ring()
	EventBus.tower_selected.connect(_on_tower_selected)
	EventBus.build_spot_clicked.connect(_on_other_selection)

func _build_range_ring() -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(data.attack_range - 0.09, 0.1)
	mesh.outer_radius = data.attack_range
	mesh.rings = 48
	mesh.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.4, 0.9, 1.0, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_range_ring = MeshInstance3D.new()
	_range_ring.mesh = mesh
	_range_ring.material_override = material
	_range_ring.position.y = 0.12
	_range_ring.visible = false
	add_child(_range_ring)
	if data != null:
		_range_ring.scale = Vector3.ONE * 1.02

func _on_tower_selected(selected: Node3D) -> void:
	if _range_ring:
		_range_ring.visible = selected == self

func _on_other_selection(_spot: Node3D) -> void:
	if _range_ring:
		_range_ring.visible = false

func _physics_process(delta: float) -> void:
	_idle_time += delta
	if turret != null and not is_disabled:
		turret.position.y = _turret_base_y + sin(_idle_time * 2.2) * 0.012
	if is_disabled:
		return
	_cooldown -= delta
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or not _is_valid(target):
		_retarget_timer = 0.1
		target = _find_target()
	if target == null:
		return
	_aim(delta)
	if _cooldown <= 0.0:
		_cooldown = 1.0 / data.fire_rate
		_fire()

func cycle_target_mode() -> void:
	target_mode = ((target_mode + 1) % TargetMode.size()) as TargetMode
	target = null

func disable_for(seconds: float) -> void:
	if is_disabled or seconds <= 0.0:
		return
	is_disabled = true
	target = null
	_show_status("DISABLED", Color(0.78, 0.5, 1.0))
	EventBus.tower_disabled.emit(global_position + Vector3.UP * 2.0, seconds)
	await get_tree().create_timer(seconds, false).timeout
	if not is_instance_valid(self):
		return
	is_disabled = false
	_hide_status()

func _show_status(text: String, color: Color) -> void:
	if _status_label == null:
		_status_label = Label3D.new()
		_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_status_label.no_depth_test = true
		_status_label.font_size = 44
		_status_label.pixel_size = 0.006
		_status_label.outline_size = 10
		_status_label.outline_modulate = Color(0.03, 0.02, 0.06, 1.0)
		_status_label.position = Vector3(0, 3.6, 0)
		add_child(_status_label)
	_status_label.text = text
	_status_label.modulate = color
	_status_label.visible = true

func _hide_status() -> void:
	if _status_label:
		_status_label.visible = false

func _is_valid(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy) or enemy.is_dead:
		return false
	if enemy.data.is_flying and not data.can_hit_flying:
		return false
	var a := Vector2(global_position.x, global_position.z)
	var b := Vector2(enemy.global_position.x, enemy.global_position.z)
	return a.distance_squared_to(b) <= data.attack_range * data.attack_range

func _find_target() -> Enemy:
	var best: Enemy = null
	var best_score: float = -INF
	var candidates: Array[Node3D] = []
	if detection_area:
		for body: Node3D in detection_area.get_overlapping_bodies():
			candidates.append(body)
		for area: Area3D in detection_area.get_overlapping_areas():
			var hurtbox_enemy := area.get_parent() as Enemy
			if hurtbox_enemy:
				candidates.append(hurtbox_enemy)
	if candidates.is_empty():
		for node in get_tree().get_nodes_in_group(&"enemies"):
			var candidate := node as Node3D
			if candidate:
				candidates.append(candidate)
	for node: Node3D in candidates:
		var enemy := node as Enemy
		if enemy == null or not _is_valid(enemy):
			continue
		var score: float = 0.0
		match target_mode:
			TargetMode.FIRST:
				score = -enemy.remaining_distance()
			TargetMode.LAST:
				score = enemy.remaining_distance()
			TargetMode.STRONGEST:
				score = enemy.hp
			TargetMode.CLOSEST:
				score = -global_position.distance_squared_to(enemy.global_position)
		if score > best_score:
			best_score = score
			best = enemy
	return best

func _aim(delta: float) -> void:
	if turret == null:
		return
	var to: Vector3 = target.global_position - turret.global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return
	var desired_global: Basis = Basis.looking_at(to.normalized(), Vector3.UP, true)
	var parent_basis: Basis = turret.get_parent().global_basis.orthonormalized()
	var desired_local: Basis = parent_basis.inverse() * desired_global
	var weight: float = 1.0 - exp(-turn_speed * delta)
	var current_scale: Vector3 = turret.scale
	var current_rot: Quaternion = turret.basis.orthonormalized().get_rotation_quaternion()
	var target_rot: Quaternion = desired_local.orthonormalized().get_rotation_quaternion()
	turret.basis = Basis(current_rot.slerp(target_rot, weight)).scaled(current_scale)

func _fire() -> void:
	if data.projectile_scene == null:
		return
	var projectile := ProjectilePool.acquire(data.projectile_scene) as Projectile
	var from: Vector3 = muzzle.global_position if muzzle else global_position + Vector3.UP * 3.0
	projectile.launch(from, target, data)
	_play_turret_attack()
	EventBus.tower_fired.emit(from)
	if fire_sound:
		AudioPool.play_at(fire_sound, from)
	_recoil()

func _play_turret_attack() -> void:
	if turret == null:
		return
	var attack_tween := create_tween()
	attack_tween.tween_property(turret, "rotation:z", deg_to_rad(-5.0), 0.04)
	attack_tween.tween_property(turret, "rotation:z", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var flash := turret.get_node_or_null("AttackFlash") as OmniLight3D
	if flash:
		flash.light_energy = 2.5
		var flash_tween := create_tween()
		flash_tween.tween_property(flash, "light_energy", 0.0, 0.12)

func _recoil() -> void:
	if turret == null:
		return
	var tw := create_tween()
	tw.tween_property(turret, "scale", Vector3(1.08, 0.9, 1.08), 0.05)
	tw.tween_property(turret, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
