class_name Enemy
extends PathFollow3D
## Root of every enemy scene. Added as a child of a Path3D by WaveSpawner.

@export var data: EnemyData

@onready var model: Node3D = $Model
@onready var health_bar: Node = $HealthBar

var hp: float = 1.0
var max_hp: float = 1.0
var is_dead: bool = false
var is_blocked: bool = false
var blocker: Node3D

var _anim: AnimationPlayer
var _meshes: Array[GeometryInstance3D] = []
var _flash_tween: Tween
var speed_multiplier: float = 1.0
var bonus_armor: float = 0.0
var bonus_speed_multiplier: float = 1.0
var _slow_mult: float = 1.0
var _slow_time: float = 0.0
var _poison_dps: float = 0.0
var _poison_time: float = 0.0
var _buff_time: float = 0.0
var _attack_cooldown: float = 0.0
var _status_tween: Tween

func _ready() -> void:
	if data == null:
		push_error("Enemy requires EnemyData.")
		set_physics_process(false)
		return
	loop = false
	rotation_mode = PathFollow3D.ROTATION_Y
	max_hp = data.max_hp * GameManager.hp_multiplier * (1.0 + 0.05 * GameManager.current_wave)
	hp = max_hp
	if data.is_flying:
		v_offset = 2.5
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for node in model.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(node as GeometryInstance3D)
	_setup_loops()
	add_to_group(&"enemies")
	_play(&"Walk")
	EventBus.enemy_spawned.emit(self)
	if data.is_boss:
		EventBus.boss_spawned.emit(self)
		EventBus.boss_health_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if model != null and not is_blocked:
		model.position.y = sin(Time.get_ticks_msec() * 0.006 + progress) * (0.018 if data.is_flying else 0.006)
	_tick_status(delta)
	if is_dead:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if is_blocked:
		_attack_blocker()
		return
	var hero := _hero_in_range()
	if hero:
		_attack(hero)
		return
	progress += data.speed * speed_multiplier * bonus_speed_multiplier * _slow_mult * delta
	if progress_ratio >= 0.999:
		_reach_end()

func _attack_blocker() -> void:
	if not is_instance_valid(blocker):
		blocker = null
		is_blocked = false
		return
	if blocker.global_position.distance_squared_to(global_position) <= data.attack_range * data.attack_range:
		_attack(blocker)

func _hero_in_range() -> Hero:
	var hero := get_tree().get_first_node_in_group(&"heroes") as Hero
	if hero == null or hero.is_dead:
		return null
	if hero.global_position.distance_squared_to(global_position) > data.attack_range * data.attack_range:
		return null
	return hero

func _attack(target: Node3D) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_interval
	_play(&"Attack")
	_pulse_model(Color(1.0, 0.35, 0.2, 1.0))
	target.call(&"take_damage", data.attack_damage)

func remaining_distance() -> float:
	var path := get_parent() as Path3D
	return path.curve.get_baked_length() - progress

func take_damage(amount: float, type: TowerData.DamageType) -> void:
	if is_dead:
		return
	var final_dmg: float = amount
	match type:
		TowerData.DamageType.PHYSICAL:
			final_dmg *= 1.0 - clampf(data.armor + bonus_armor, 0.0, 0.9)
		TowerData.DamageType.MAGIC:
			final_dmg *= 1.0 - data.magic_resist
	hp -= final_dmg
	EventBus.damage_dealt.emit(global_position + Vector3.UP * 1.6, final_dmg)
	_update_health_bar()
	_flash()
	if hp <= 0.0:
		_die()

func heal(amount: float) -> void:
	if is_dead:
		return
	hp = minf(hp + amount, max_hp)
	_update_health_bar()

func apply_slow(multiplier: float, duration: float) -> void:
	_slow_mult = minf(_slow_mult, multiplier)
	_slow_time = maxf(_slow_time, duration)
	if _anim:
		_anim.speed_scale = _slow_mult

func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = maxf(_poison_dps, dps)
	_poison_time = maxf(_poison_time, duration)

func apply_buff(armor: float, speed_multiplier_value: float, duration: float) -> void:
	bonus_armor = maxf(bonus_armor, armor)
	bonus_speed_multiplier = maxf(bonus_speed_multiplier, speed_multiplier_value)
	_buff_time = maxf(_buff_time, duration)

func _tick_status(delta: float) -> void:
	if _buff_time > 0.0:
		_buff_time -= delta
		if _buff_time <= 0.0:
			bonus_armor = 0.0
			bonus_speed_multiplier = 1.0
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_mult = 1.0
			if _anim:
				_anim.speed_scale = 1.0
	if _poison_time > 0.0:
		_poison_time -= delta
		hp -= _poison_dps * delta
		_update_health_bar()
		if hp <= 0.0:
			_die()
		elif _poison_time <= 0.0:
			_poison_dps = 0.0

func _die() -> void:
	is_dead = true
	remove_from_group(&"enemies")
	EventBus.enemy_died.emit(self, data.gold_reward)
	if data.is_boss:
		EventBus.boss_died.emit(self)
		EventBus.camera_shake.emit(0.8)
	_play(&"Die")
	model.scale = Vector3.ONE
	var death_tween := create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(model, "rotation:z", deg_to_rad(-18.0), 0.22)
	death_tween.tween_property(model, "position:y", 0.18, 0.22)
	death_tween.set_parallel(false)
	death_tween.tween_property(model, "scale", Vector3(0.82, 0.82, 0.82), 0.28)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_method(_set_dissolve, 0.0, 1.0, 0.5)
	tw.tween_callback(queue_free)

func _reach_end() -> void:
	is_dead = true
	remove_from_group(&"enemies")
	if data.is_boss:
		EventBus.boss_died.emit(self)
	EventBus.enemy_reached_end.emit(self, data.lives_damage)
	queue_free()

func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, 0.12)
	_pulse_model(Color.WHITE)

func _pulse_model(color: Color) -> void:
	if model == null:
		return
	if _status_tween:
		_status_tween.kill()
	_status_tween = create_tween()
	_status_tween.tween_property(model, "scale", Vector3.ONE * 1.06, 0.06)
	_status_tween.tween_property(model, "scale", Vector3.ONE, 0.12)

func _set_flash(value: float) -> void:
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(&"hit_flash", value)

func _set_dissolve(value: float) -> void:
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(&"dissolve_amount", value)

func _update_health_bar() -> void:
	if health_bar and health_bar.has_method(&"set_ratio"):
		health_bar.set_ratio(clampf(hp / max_hp, 0.0, 1.0))
	if data and data.is_boss:
		EventBus.boss_health_changed.emit(hp, max_hp)

func _setup_loops() -> void:
	if _anim == null:
		return
	for anim_name: StringName in [&"Walk", &"Idle"]:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	if _anim and _anim.has_animation(&"Walk"):
		_anim.get_animation(&"Walk").loop_mode = Animation.LOOP_LINEAR

func _play(anim_name: StringName) -> void:
	if _anim and _anim.has_animation(anim_name):
		_anim.play(anim_name, 0.15)
