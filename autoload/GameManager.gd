extends Node

enum State { BUILD, WAVE, WON, LOST }

var state: State = State.BUILD
var max_lives: int = 20
var hp_multiplier: float = 1.0
var current_wave: int = 0
var lives: int = 20:
	set(value):
		lives = maxi(value, 0)
		EventBus.lives_changed.emit(lives)
		if lives == 0 and state != State.LOST and state != State.WON:
			_lose()

func _ready() -> void:
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)
	EventBus.all_waves_cleared.connect(_win)

func start_level(data: LevelData) -> void:
	if data == null:
		push_error("GameManager.start_level requires LevelData.")
		return
	state = State.BUILD
	current_wave = 0
	hp_multiplier = data.enemy_hp_multiplier
	max_lives = data.start_lives + MetaProgression.bonus_start_lives()
	lives = max_lives
	Economy.reset(data.start_gold + MetaProgression.bonus_start_gold())
	Engine.time_scale = 1.0

func calc_stars() -> int:
	if lives == max_lives:
		return 3
	if lives >= ceili(max_lives * 0.5):
		return 2
	return 1

func _on_enemy_reached_end(_enemy: Node3D, damage: int) -> void:
	if state == State.WON or state == State.LOST:
		return
	lives -= damage

func _win() -> void:
	if state == State.WON or state == State.LOST:
		return
	state = State.WON
	EventBus.level_won.emit(calc_stars())

func _lose() -> void:
	state = State.LOST
	EventBus.level_lost.emit()
