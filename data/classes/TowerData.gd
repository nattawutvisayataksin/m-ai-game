class_name TowerData
extends Resource

enum DamageType { PHYSICAL, MAGIC, TRUE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var cost: int = 70
@export var damage_min: float = 4.0
@export var damage_max: float = 6.0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var attack_range: float = 7.0
@export var fire_rate: float = 1.6
@export var aoe_radius: float = 0.0
@export_range(0.0, 1.0) var slow_amount: float = 0.0
@export var slow_duration: float = 0.0
@export var poison_dps: float = 0.0
@export var poison_duration: float = 0.0
@export var can_hit_flying: bool = true
@export var projectile_scene: PackedScene
@export var tower_scene: PackedScene
@export var upgrade_to: Array[TowerData] = []
@export_range(0.0, 1.0) var sell_ratio: float = 0.7
