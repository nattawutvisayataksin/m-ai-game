class_name EnemyData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: float = 40.0
@export var speed: float = 2.0
@export_range(0.0, 0.9) var armor: float = 0.0
@export_range(0.0, 0.9) var magic_resist: float = 0.0
@export var gold_reward: int = 6
@export var lives_damage: int = 1
@export var is_flying: bool = false
@export var is_boss: bool = false
@export var attack_damage: float = 8.0
@export var attack_interval: float = 1.2
@export var attack_range: float = 1.6
@export var scene: PackedScene
