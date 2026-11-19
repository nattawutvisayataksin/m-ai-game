class_name SaboteurEnemy
extends Enemy
## Elite saboteur: channels beside a tower for a moment, then disables it.

@export var disable_radius: float = 6.0
@export var disable_duration: float = 3.0
@export var disable_interval: float = 8.0
@export var channel_time: float = 0.6

var _cooldown: float = 0.0
var _channel: float = 0.0
var _pending_tower: Tower

func _ready() -> void:
	super._ready()
	_cooldown = disable_interval

func _process(delta: float) -> void:
	if is_dead or model == null:
		return
	model.rotate_y(delta * 1.8)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _channel > 0.0:
		_tick_status(delta)
		if is_dead:
			return
		_channel -= delta
		if _channel <= 0.0:
			_trigger_disable()
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		var tower := _nearest_tower()
		if tower:
			_cooldown = disable_interval
			_pending_tower = tower
			_channel = channel_time
			_play(&"Idle")
			return
	super._physics_process(delta)

func _nearest_tower() -> Tower:
	var nearest: Tower = null
	var best: float = disable_radius * disable_radius
	for node in get_tree().get_nodes_in_group(&"towers"):
		var tower := node as Tower
		if tower == null or tower.is_disabled:
			continue
		var distance: float = global_position.distance_squared_to(tower.global_position)
		if distance <= best:
			best = distance
			nearest = tower
	return nearest

func _trigger_disable() -> void:
	var tower := _pending_tower
	_pending_tower = null
	_channel = 0.0
	_play(&"Walk")
	if not is_instance_valid(tower) or tower.is_disabled:
		return
	if global_position.distance_squared_to(tower.global_position) > disable_radius * disable_radius:
		return
	tower.disable_for(disable_duration)
