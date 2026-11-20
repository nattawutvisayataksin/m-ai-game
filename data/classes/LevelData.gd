class_name LevelData
extends Resource

@export var id: StringName = &"level_01"
@export var display_name: String = ""
@export var start_gold: int = 260
@export var start_lives: int = 20
@export var enemy_hp_multiplier: float = 1.0
@export_group("Wave Pacing")
@export var time_between_waves: float = 20.0
@export var early_call_gold_per_sec: float = 1.5
@export var starting_build_spots: int = 0
@export var waves: Array[WaveData] = []
