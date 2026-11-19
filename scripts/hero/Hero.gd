class_name Hero
extends CharacterBody3D

signal xp_changed(current: int, required: int)
signal level_changed(level: int)
signal skill_cooldown_changed(skill_index: int, remaining: float, duration: float)

const METEOR_WARNING_SCENE: PackedScene = preload("res://scenes/vfx/MeteorWarning.tscn")

@export var max_hp: float = 120.0
@export var move_speed: float = 5.0
@export var attack_damage: float = 18.0
@export var attack_rate: float = 1.2
@export var attack_range: float = 5.0
@export var xp_per_kill: int = 10
@export var respawn_delay: float = 15.0
@export var meteor_damage: float = 80.0
@export var meteor_radius: float = 4.0
@export var meteor_delay: float = 1.5
@export var meteor_cooldown: float = 12.0
@export var soldier_scene: PackedScene
@export var reinforcement_duration: float = 20.0
@export var reinforcement_cooldown: float = 20.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: Node3D = $Model

var level: int = 1
var xp: int = 0
var xp_required: int = 100
var is_dead: bool = false
var hp: float = 120.0
var meteor_remaining: float = 0.0
var reinforcements_remaining: float = 0.0
var destination: Vector3
var _spawn_position: Vector3
var _attack_timer: float = 0.0
var _respawn_timer: float = 0.0
var _meteor_target: Vector3

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	add_to_group(&"heroes")
	_spawn_position = global_position
	hp = max_hp
	destination = global_position
	navigation_agent.target_position = destination
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.8
	navigation_agent.avoidance_enabled = true
	_emit_health.call_deferred()
	EventBus.hero_level_changed.emit.call_deferred(level, xp, xp_required)

func _physics_process(delta: float) -> void:
	if is_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return
	meteor_remaining = maxf(meteor_remaining - delta, 0.0)
	reinforcements_remaining = maxf(reinforcements_remaining - delta, 0.0)
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_move_to_destination(delta)
	_auto_attack()
	skill_cooldown_changed.emit(0, meteor_remaining, meteor_cooldown)
	skill_cooldown_changed.emit(1, reinforcements_remaining, reinforcement_cooldown)

func set_move_destination(world_position: Vector3) -> void:
	if is_dead:
		return
	destination = world_position
	navigation_agent.target_position = world_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			return
		var origin := camera.project_ray_origin(mouse_event.position)
		var end := origin + camera.project_ray_normal(mouse_event.position) * 1000.0
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.has("position"):
			if hit.get("collider") is BuildSpot:
				return
			set_move_destination(hit["position"] as Vector3)

func use_meteor(target_position: Vector3) -> bool:
	if is_dead or meteor_remaining > 0.0:
		return false
	meteor_remaining = meteor_cooldown
	_meteor_target = target_position
	if METEOR_WARNING_SCENE:
		var warning := METEOR_WARNING_SCENE.instantiate() as Node3D
		get_tree().current_scene.add_child(warning)
		warning.global_position = target_position
	_meteor_strike()
	return true

func best_meteor_target() -> Vector3:
	var enemies: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy != null and not enemy.is_dead:
			enemies.append(enemy)
	if enemies.is_empty():
		return global_position
	var best_count: int = 0
	var best_center: Vector3 = enemies[0].global_position
	for candidate: Enemy in enemies:
		var center: Vector3 = Vector3.ZERO
		var count: int = 0
		for enemy: Enemy in enemies:
			if candidate.global_position.distance_squared_to(enemy.global_position) <= meteor_radius * meteor_radius:
				center += enemy.global_position
				count += 1
		if count > best_count:
			best_count = count
			best_center = center / float(count)
	return best_center

func use_reinforcements() -> bool:
	if is_dead or reinforcements_remaining > 0.0 or soldier_scene == null:
		return false
	reinforcements_remaining = reinforcement_cooldown
	for index: int in 2:
		var soldier := soldier_scene.instantiate() as Soldier
		get_tree().current_scene.add_child(soldier)
		var offset := Vector3(float(index) * 1.5 - 0.75, 0.0, 1.5)
		soldier.setup(global_position + offset)
		if reinforcement_duration > 0.0:
			_destroy_after(soldier, reinforcement_duration)
	return true

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_emit_health()
	EventBus.damage_dealt.emit(global_position + Vector3.UP * 2.0, amount)
	if hp <= 0.0:
		_die()

func _move_to_destination(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		velocity = Vector3.ZERO
		return
	direction = direction.normalized()
	velocity = direction * move_speed
	move_and_slide()
	if Vector2(velocity.x, velocity.z).length_squared() > 0.01:
		model.global_basis = model.global_basis.slerp(Basis.looking_at(direction, Vector3.UP, true), 1.0 - exp(-10.0 * delta))

func _auto_attack() -> void:
	if _attack_timer > 0.0:
		return
	var target := _nearest_enemy()
	if target:
		_attack_timer = 1.0 / attack_rate
		target.take_damage(attack_damage, TowerData.DamageType.PHYSICAL)

func _nearest_enemy() -> Enemy:
	var nearest: Enemy
	var nearest_distance: float = attack_range * attack_range
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _meteor_strike() -> void:
	await get_tree().create_timer(meteor_delay, false).timeout
	if is_dead:
		return
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_dead and enemy.global_position.distance_squared_to(_meteor_target) <= meteor_radius * meteor_radius:
			enemy.take_damage(meteor_damage, TowerData.DamageType.MAGIC)
	EventBus.camera_shake.emit(0.6)
	EventBus.meteor_impacted.emit(_meteor_target)

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required = int(roundi(float(xp_required) * 1.25))
		attack_damage *= 1.15
		hp = max_hp
		_emit_health()
		EventBus.camera_shake.emit(0.25)
		level_changed.emit(level)
	xp_changed.emit(xp, xp_required)
	EventBus.hero_level_changed.emit(level, xp, xp_required)

func _on_enemy_died(_enemy: Node3D, _reward: int) -> void:
	add_xp(xp_per_kill)

func _die() -> void:
	is_dead = true
	hp = 0.0
	visible = false
	velocity = Vector3.ZERO
	_respawn_timer = respawn_delay
	_emit_health()

func _respawn() -> void:
	is_dead = false
	visible = true
	hp = max_hp
	global_position = _spawn_position
	_emit_health()

func _emit_health() -> void:
	EventBus.hero_health_changed.emit(hp, max_hp)

func _destroy_after(node: Node, seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	if is_instance_valid(node):
		node.queue_free()
