extends Node
## Generates lightweight placeholder SFX and routes gameplay events to the audio pool.

const SAMPLE_RATE: int = 22050
const MUSIC_BUS: StringName = &"Music"
var _music_chords: Array[PackedFloat32Array] = [
	PackedFloat32Array([110.0, 130.81, 164.81]),
	PackedFloat32Array([87.31, 110.0, 130.81]),
	PackedFloat32Array([130.81, 164.81, 196.0]),
	PackedFloat32Array([98.0, 123.47, 146.83]),
]

var _shot: AudioStreamWAV
var _hit: AudioStreamWAV
var _coin: AudioStreamWAV
var _build: AudioStreamWAV
var _wave: AudioStreamWAV
var _win: AudioStreamWAV
var _lose: AudioStreamWAV
var _meteor: AudioStreamWAV
var _rally: AudioStreamWAV
var _heal: AudioStreamWAV
var _blessing: AudioStreamWAV
var _sabotage: AudioStreamWAV
var _fanfare: AudioStreamWAV
var _music: AudioStreamWAV
var _music_player: AudioStreamPlayer
var _ui: AudioStreamPlayer
var _last_hit_ms: int = -1000

func _ready() -> void:
	_shot = _tone(980.0, 0.07, 0.22, 1)
	_hit = _tone(220.0, 0.05, 0.2, 0, 140.0)
	_coin = _notes(PackedFloat32Array([1318.5, 1760.0]), 0.055, 0.2)
	_build = _notes(PackedFloat32Array([523.25, 659.25, 783.99]), 0.06, 0.22)
	_wave = _notes(PackedFloat32Array([392.0, 523.25]), 0.11, 0.18)
	_win = _notes(PackedFloat32Array([523.25, 659.25, 783.99, 1046.5]), 0.13, 0.22)
	_lose = _notes(PackedFloat32Array([392.0, 329.63, 261.63]), 0.16, 0.22)
	_meteor = _tone(80.0, 0.55, 0.45, 0, 36.0)
	_rally = _notes(PackedFloat32Array([440.0, 554.37, 659.25]), 0.08, 0.25)
	_heal = _notes(PackedFloat32Array([783.99, 1046.5]), 0.08, 0.14)
	_blessing = _notes(PackedFloat32Array([659.25, 987.77, 1318.5]), 0.09, 0.2)
	_sabotage = _tone(520.0, 0.3, 0.28, 1, 80.0)
	_fanfare = _notes(PackedFloat32Array([523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98]), 0.15, 0.24)
	_music = _pad_loop()
	_ensure_music_bus()
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -21.0
	_music_player.bus = MUSIC_BUS
	_music_player.stream = _music
	add_child(_music_player)
	set_music_volume(float(SaveManager.get_setting(&"music", 0.8)))
	_music_player.play()
	_ui = AudioStreamPlayer.new()
	_ui.volume_db = -8.0
	_ui.bus = &"SFX"
	add_child(_ui)
	EventBus.damage_dealt.connect(_on_damage)
	EventBus.tower_fired.connect(_on_tower_fired)
	EventBus.tower_built.connect(_on_tower_built)
	EventBus.coin_pop.connect(_on_coin_pop)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.meteor_impacted.connect(_on_meteor_impacted)
	EventBus.rally_point_requested.connect(_on_rally_point)
	EventBus.heal_dealt.connect(_on_heal_dealt)
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.tower_disabled.connect(_on_tower_disabled)
	EventBus.campaign_completed.connect(_on_campaign_completed)

func _on_damage(world_position: Vector3, _amount: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_hit_ms < 60:
		return
	_last_hit_ms = now
	AudioPool.play_at(_hit, world_position, -14.0)

func _on_tower_fired(world_position: Vector3) -> void:
	AudioPool.play_at(_shot, world_position, -11.0)

func _on_tower_built(world_position: Vector3) -> void:
	AudioPool.play_at(_build, world_position, -7.0)

func _on_coin_pop(world_position: Vector3, _amount: int) -> void:
	AudioPool.play_at(_coin, world_position, -9.0)

func _on_wave_started(_index: int) -> void:
	_play_ui(_wave)

func _on_meteor_impacted(world_position: Vector3) -> void:
	AudioPool.play_at(_meteor, world_position, -4.0)

func _on_rally_point(world_position: Vector3) -> void:
	AudioPool.play_at(_rally, world_position, -5.0)

func _on_heal_dealt(world_position: Vector3, _amount: float) -> void:
	AudioPool.play_at(_heal, world_position, -15.0)

func _on_level_won(_stars: int) -> void:
	_play_ui(_win)

func _on_upgrade_purchased(_track: StringName, _level: int) -> void:
	_play_ui(_blessing)

func _on_tower_disabled(world_position: Vector3, _duration: float) -> void:
	AudioPool.play_at(_sabotage, world_position, -6.0)

func _on_campaign_completed() -> void:
	_play_ui(_fanfare)

func _on_level_lost() -> void:
	_play_ui(_lose)

func _play_ui(stream: AudioStream) -> void:
	if stream == null:
		return
	_ui.stream = stream
	_ui.play()

func _ensure_music_bus() -> int:
	var index: int = AudioServer.get_bus_index(MUSIC_BUS)
	if index != -1:
		return index
	index = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, MUSIC_BUS)
	AudioServer.set_bus_send(index, &"Master")
	return index

func set_music_volume(value: float) -> void:
	var index: int = _ensure_music_bus()
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))

func _tone(start_freq: float, duration: float, volume: float, waveform: int = 0, end_freq: float = -1.0) -> AudioStreamWAV:
	return _to_stream(_tone_samples(start_freq, duration, volume, waveform, end_freq))

func _tone_samples(start_freq: float, duration: float, volume: float, waveform: int = 0, end_freq: float = -1.0) -> PackedFloat32Array:
	var count: int = int(float(SAMPLE_RATE) * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase: float = 0.0
	var target_freq: float = end_freq if end_freq > 0.0 else start_freq
	for index: int in count:
		var t: float = float(index) / float(count)
		var frequency: float = lerpf(start_freq, target_freq, t)
		phase += TAU * frequency / float(SAMPLE_RATE)
		var value: float = sin(phase)
		if waveform == 1:
			value = 1.0 if value >= 0.0 else -1.0
		samples[index] = value * pow(1.0 - t, 1.6) * volume
	return samples

func _notes(frequencies: PackedFloat32Array, step: float, volume: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for frequency: float in frequencies:
		samples.append_array(_tone_samples(frequency, step, volume))
	return _to_stream(samples)

func _pad_loop() -> AudioStreamWAV:
	var segment: float = 2.5
	var count: int = int(float(SAMPLE_RATE) * segment * float(_music_chords.size()))
	var samples := PackedFloat32Array()
	samples.resize(count)
	for chord_index: int in _music_chords.size():
		var chord: PackedFloat32Array = _music_chords[chord_index]
		var start: int = int(float(SAMPLE_RATE) * segment * float(chord_index))
		var length: int = int(float(SAMPLE_RATE) * segment)
		for index: int in length:
			var t: float = float(index) / float(length)
			var envelope: float = sin(t * PI)
			var phase_time: float = float(index) / float(SAMPLE_RATE)
			var value: float = 0.0
			for frequency: float in chord:
				var cycles: float = round(frequency * segment)
				value += sin(TAU * cycles * phase_time / segment + float(chord_index))
			samples[start + index] = value * 0.08 * envelope
	var stream := _to_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index: int in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
