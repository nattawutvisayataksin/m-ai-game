class_name BossEnemy
extends Enemy
## Boss behavior layered on top of Enemy: ground slam, minion summons, enrage phase.

const SUMMON_THRESHOLDS: PackedFloat32Array = [0.65, 0.35]
const SLAM_WARNING_SCENE: PackedScene = preload("res://scenes/vfx/BossSlamWarning.tscn")

@export var slam_radius: float = 4.5
@export var slam_damage: float = 22.0
@export var slam_interval: float = 6.0
@export var slam_windup: float = 0.9
@export var summon_data: EnemyData
@export var summon_group_size: int = 3
@export var phase_two_speed: float = 1.35
@export var slam_vfx: PackedScene

var _slam_timer: float = 0.0
var _next_summon_index: int = 0
var _phase_two: bool = false

func _ready() -> void:
	super._ready()
	_slam_timer = slam_interval

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_slam_timer -= delta
	if _slam_timer <= 0.0:
		_slam_timer = slam_interval
		_slam()
	_check_phases()
	super._physics_process(delta)

func _slam() -> void:
	var origin: Vector3 = global_position
	_spawn_warning(origin)
	await get_tree().create_timer(slam_windup, false).timeout
	if is_dead:
		return
	EventBus.camera_shake.emit(0.45)
	_spawn_slam_vfx(origin)
	_damage_radius(origin)

func _spawn_warning(origin: Vector3) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var warning := SLAM_WARNING_SCENE.instantiate() as SlamWarning
	if warning == null:
		return
	warning.duration = slam_windup
	warning.radius = slam_radius
	scene_root.add_child(warning)
	warning.global_position = origin + Vector3.UP * 0.02

func _damage_radius(origin: Vector3) -> void:
	var radius_squared: float = slam_radius * slam_radius
	var hero := get_tree().get_first_node_in_group(&"heroes") as Hero
	if hero and not hero.is_dead and hero.global_position.distance_squared_to(origin) <= radius_squared:
		hero.take_damage(slam_damage)
	for node in get_tree().get_nodes_in_group(&"soldiers"):
		var soldier := node as Soldier
		if soldier and soldier.global_position.distance_squared_to(origin) <= radius_squared:
			soldier.take_damage(slam_damage)

func _spawn_slam_vfx(origin: Vector3) -> void:
	if slam_vfx == null:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var effect := slam_vfx.instantiate() as Node3D
	scene_root.add_child(effect)
	effect.global_position = origin + Vector3.UP * 0.2
	effect.scale = Vector3.ONE * 2.0

func _check_phases() -> void:
	var ratio: float = hp / maxf(max_hp, 0.001)
	if not _phase_two and ratio <= 0.5:
		_phase_two = true
		speed_multiplier = phase_two_speed
		slam_interval *= 0.65
		EventBus.camera_shake.emit(0.3)
	while summon_data != null and _next_summon_index < SUMMON_THRESHOLDS.size() \
			and ratio <= SUMMON_THRESHOLDS[_next_summon_index]:
		_next_summon_index += 1
		_summon_minions()

func _summon_minions() -> void:
	if summon_data == null or summon_data.scene == null:
		return
	var path := get_parent() as Path3D
	if path == null:
		return
	for index: int in summon_group_size:
		var minion := summon_data.scene.instantiate() as Enemy
		if minion == null:
			continue
		minion.data = summon_data
		path.add_child(minion)
		minion.progress = maxf(progress - 1.5 - float(index) * 1.2, 0.0)
