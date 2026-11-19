class_name HealerEnemy
extends Enemy
## Support enemy: periodically heals nearby non-boss allies and emits a heal event.

@export var heal_radius: float = 7.0
@export var heal_amount: float = 16.0
@export var heal_interval: float = 5.0
@export var bob_height: float = 0.25
@export var bob_speed: float = 2.2

var _heal_timer: float = 0.0
var _bob_time: float = 0.0

func _ready() -> void:
	super._ready()
	_heal_timer = heal_interval

func _process(delta: float) -> void:
	if is_dead:
		return
	_bob_time += delta
	model.position.y = sin(_bob_time * bob_speed) * bob_height

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_heal_timer -= delta
	if _heal_timer <= 0.0:
		_heal_timer = heal_interval
		_heal_allies()
	super._physics_process(delta)

func _heal_allies() -> void:
	var radius_squared: float = heal_radius * heal_radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var ally := node as Enemy
		if ally == null or ally == self or ally.is_dead:
			continue
		if ally.data and ally.data.is_boss:
			continue
		if ally.hp >= ally.max_hp:
			continue
		if ally.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		ally.heal(heal_amount)
		EventBus.heal_dealt.emit(ally.global_position + Vector3.UP * 1.6, heal_amount)
