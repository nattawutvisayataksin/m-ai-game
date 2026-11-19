class_name WaveSpawner
extends Node

@export var level_data: LevelData
@export var paths: Array[Path3D] = []
@export var time_between_waves: float = 20.0
@export var early_call_gold_per_sec: float = 1.5

var current_wave: int = -1
var countdown: float = 0.0
var waiting_for_next: bool = true
var _active_groups: int = 0

func _ready() -> void:
	_resolve_paths()
	EventBus.enemy_died.connect(_on_enemy_removed.unbind(2))
	EventBus.enemy_reached_end.connect(_on_enemy_removed.unbind(2))

func _resolve_paths() -> void:
	if not paths.is_empty():
		return
	for sibling in get_parent().get_children():
		var path := sibling as Path3D
		if path:
			paths.append(path)

func _process(delta: float) -> void:
	# First wave waits for the player's Start button.
	if level_data == null or not waiting_for_next or current_wave < 0:
		return
	countdown -= delta
	if countdown <= 0.0:
		start_next_wave()

func total_waves() -> int:
	if level_data == null:
		return 0
	return level_data.waves.size()

func is_current_wave_boss() -> bool:
	if level_data == null or current_wave < 0 or current_wave >= level_data.waves.size():
		return false
	return level_data.waves[current_wave].is_boss_wave

func next_wave_summary() -> String:
	if level_data == null:
		return ""
	var index: int = current_wave + 1
	if index < 0 or index >= level_data.waves.size():
		return "Final wave"
	var wave: WaveData = level_data.waves[index]
	var parts: Array[String] = []
	for group: SpawnGroup in wave.groups:
		if group.enemy == null:
			continue
		parts.append("%d x %s" % [group.count, group.enemy.display_name])
	var summary: String = ", ".join(parts)
	if wave.is_boss_wave:
		summary = "BOSS  -  " + summary
	return summary

func call_next_wave() -> void:
	if level_data == null or not waiting_for_next:
		return
	if current_wave >= 0 and countdown > 0.0:
		Economy.add(int(countdown * early_call_gold_per_sec))
	start_next_wave()

func start_next_wave() -> void:
	if level_data == null:
		return
	if current_wave + 1 >= level_data.waves.size():
		return
	waiting_for_next = false
	current_wave += 1
	GameManager.current_wave = current_wave
	GameManager.state = GameManager.State.WAVE
	EventBus.wave_started.emit(current_wave)
	var wave: WaveData = level_data.waves[current_wave]
	for group in wave.groups:
		_run_group(group)

func _run_group(group: SpawnGroup) -> void:
	_active_groups += 1
	if group.delay > 0.0:
		await get_tree().create_timer(group.delay, false).timeout
	for i in group.count:
		if GameManager.state == GameManager.State.LOST:
			break
		_spawn(group.enemy, group.path_index)
		await get_tree().create_timer(group.interval, false).timeout
	_active_groups -= 1
	if _active_groups == 0:
		_on_wave_spawned()

func _spawn(enemy_data: EnemyData, path_index: int) -> void:
	if enemy_data == null or enemy_data.scene == null or paths.is_empty():
		return
	var enemy := enemy_data.scene.instantiate() as Enemy
	enemy.data = enemy_data
	paths[clampi(path_index, 0, paths.size() - 1)].add_child(enemy)

func _on_wave_spawned() -> void:
	EventBus.wave_spawn_finished.emit(current_wave)
	if current_wave < total_waves() - 1:
		waiting_for_next = true
		countdown = time_between_waves
	_check_victory()

func _on_enemy_removed() -> void:
	_check_victory.call_deferred()

func _check_victory() -> void:
	if current_wave < total_waves() - 1 or _active_groups > 0:
		return
	if get_tree().get_nodes_in_group(&"enemies").is_empty():
		EventBus.all_waves_cleared.emit()
