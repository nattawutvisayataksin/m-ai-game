class_name Barracks
extends Tower

const RALLY_FLAG_SCENE: PackedScene = preload("res://scenes/world/RallyFlag.tscn")

@export var soldier_scene: PackedScene
@export var rally_range: float = 8.0
@export var soldier_count: int = 3
@export var respawn_seconds: float = 10.0

var rally_point: Vector3
var _soldiers: Array[Soldier] = []
var _respawn_timer: float = 0.0
var _flag: Node3D = null

func _ready() -> void:
	super._ready()
	rally_point = global_position + Vector3.FORWARD * 2.5
	_update_flag()
	_spawn_missing_soldiers()

func _exit_tree() -> void:
	if is_instance_valid(_flag):
		_flag.queue_free()

func _physics_process(delta: float) -> void:
	if is_disabled:
		return
	_respawn_timer = maxf(_respawn_timer - delta, 0.0)
	for soldier: Soldier in _soldiers.duplicate():
		if not is_instance_valid(soldier):
			_soldiers.erase(soldier)
	if _respawn_timer <= 0.0 and _soldiers.size() < soldier_count:
		_spawn_missing_soldiers()

func set_rally_point(world_position: Vector3) -> void:
	var offset := world_position - global_position
	if offset.length() <= rally_range:
		rally_point = world_position
		_update_flag()
		EventBus.rally_point_requested.emit(rally_point)
		var index: int = 0
		for soldier: Soldier in _soldiers:
			if is_instance_valid(soldier):
				var soldier_offset := Vector3(float(index - 1) * 0.8, 0.0, 0.0)
				soldier.setup(rally_point + soldier_offset)
				index += 1

func _update_flag() -> void:
	if _flag == null and RALLY_FLAG_SCENE:
		_flag = RALLY_FLAG_SCENE.instantiate() as Node3D
		get_tree().current_scene.add_child(_flag)
	if _flag:
		_flag.global_position = rally_point

func _spawn_missing_soldiers() -> void:
	if soldier_scene == null:
		return
	while _soldiers.size() < soldier_count:
		var soldier := soldier_scene.instantiate() as Soldier
		add_child(soldier)
		_soldiers.append(soldier)
		soldier.died.connect(_on_soldier_died.bind(soldier), CONNECT_ONE_SHOT)
		var index: int = _soldiers.size() - 1
		var soldier_offset := Vector3(float(index - 1) * 0.8, 0.0, 0.0)
		soldier.setup(rally_point + soldier_offset)

func _on_soldier_died(soldier: Soldier) -> void:
	_soldiers.erase(soldier)
	_respawn_timer = respawn_seconds
