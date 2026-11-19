extends Node

const SFX_BUS: StringName = &"SFX"

@export var pool_size: int = 16
@export var default_stream: AudioStream

var _players: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	_ensure_sfx_bus()
	for index: int in pool_size:
		var player := AudioStreamPlayer3D.new()
		player.unit_size = 18.0
		player.max_distance = 90.0
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	set_sfx_volume(float(SaveManager.get_setting(&"sfx", 0.8)))

func _ensure_sfx_bus() -> int:
	var index: int = AudioServer.get_bus_index(SFX_BUS)
	if index != -1:
		return index
	index = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, SFX_BUS)
	AudioServer.set_bus_send(index, &"Master")
	return index

func set_sfx_volume(value: float) -> void:
	var index: int = _ensure_sfx_bus()
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))

func play_at(stream: AudioStream, world_position: Vector3, volume_db: float = 0.0) -> void:
	var player := _find_available()
	if player == null:
		return
	player.stream = stream if stream else default_stream
	if player.stream == null:
		return
	player.global_position = world_position
	player.volume_db = volume_db
	player.play()

func stop_all() -> void:
	for player: AudioStreamPlayer3D in _players:
		player.stop()
		player.stream = null

func _find_available() -> AudioStreamPlayer3D:
	for player: AudioStreamPlayer3D in _players:
		if not player.playing:
			return player
	return null
