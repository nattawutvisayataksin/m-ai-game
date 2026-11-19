extends Node

var gold: int = 0:
	set(value):
		gold = maxi(value, 0)
		EventBus.gold_changed.emit(gold)

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

func reset(start_gold: int) -> void:
	gold = start_gold

func can_afford(cost: int) -> bool:
	return gold >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	return true

func add(amount: int) -> void:
	gold += amount

func _on_enemy_died(_enemy: Node3D, reward: int) -> void:
	add(reward)
	if is_instance_valid(_enemy):
		EventBus.coin_pop.emit(_enemy.global_position, reward)
