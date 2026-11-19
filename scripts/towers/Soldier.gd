class_name Soldier
extends Node3D

signal died

@export var max_hp: float = 60.0
@export var damage: float = 8.0
@export var attack_rate: float = 1.0
@export var move_speed: float = 4.0
@export var block_range: float = 1.4

var hp: float = 60.0
var target: Enemy
var _home: Vector3
var _cooldown: float = 0.0

@onready var health_bar: Node = get_node_or_null("HealthBar")

func _ready() -> void:
	add_to_group(&"soldiers")

func setup(home: Vector3) -> void:
	_home = home
	hp = max_hp
	global_position = home
	_update_health_bar()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead:
		target = _find_target()
	if target == null:
		_move_to(_home, delta)
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance > block_range:
		_move_to(target.global_position, delta)
	else:
		target.is_blocked = true
		target.blocker = self
		_cooldown -= delta
		if _cooldown <= 0.0:
			_cooldown = 1.0 / attack_rate
			var multiplied: float = damage * MetaProgression.tower_damage_multiplier()
			target.take_damage(multiplied, TowerData.DamageType.PHYSICAL)

func _exit_tree() -> void:
	if is_instance_valid(target):
		if target.blocker == self:
			target.blocker = null
		target.is_blocked = false

func take_damage(amount: float) -> void:
	hp -= amount
	_update_health_bar()
	EventBus.damage_dealt.emit(global_position + Vector3.UP * 1.2, amount)
	if hp <= 0.0:
		if is_instance_valid(target) and target.is_blocked:
			target.is_blocked = false
		died.emit()
		queue_free()

func _update_health_bar() -> void:
	if health_bar and health_bar.has_method(&"set_ratio"):
		health_bar.set_ratio(clampf(hp / max_hp, 0.0, 1.0))

func _find_target() -> Enemy:
	var nearest: Enemy
	var nearest_distance: float = INF
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _move_to(destination: Vector3, delta: float) -> void:
	var offset := destination - global_position
	offset.y = 0.0
	if offset.length_squared() <= 0.01:
		return
	global_position += offset.normalized() * move_speed * delta
	look_at(global_position + offset.normalized(), Vector3.UP, true)
