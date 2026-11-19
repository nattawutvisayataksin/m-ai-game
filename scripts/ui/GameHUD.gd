class_name GameHUD
extends CanvasLayer

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/SettingsPanel.tscn")
const CAMPAIGN_FINALE_SCENE: PackedScene = preload("res://scenes/ui/CampaignFinale.tscn")

@export var wave_spawner_path: NodePath

@onready var lives_label: Label = $TopBar/Lives
@onready var gold_label: Label = $TopBar/Gold
@onready var wave_label: Label = $TopBar/Wave
@onready var next_wave_label: Label = $NextWaveInfo
@onready var tower_alert_label: Label = $TowerAlert
@onready var damage_flash: ColorRect = $DamageFlash
@onready var hero_health_label: Label = $TopBar/HeroHP
@onready var wave_banner: Label = $WaveBanner
@onready var next_wave_button: Button = $BottomBar/NextWave
@onready var speed_button: Button = $BottomBar/Speed
@onready var pause_button: Button = $BottomBar/Pause
@onready var pause_panel: Control = $PausePanel
@onready var victory_panel: Control = $VictoryPanel
@onready var title_label: Label = $VictoryPanel/Title
@onready var stars_label: Label = $VictoryPanel/Stars
@onready var stats_label: Label = $VictoryPanel/Stats
@onready var shards_label: Label = $VictoryPanel/Shards
@onready var continue_button: Button = $VictoryPanel/Continue
@onready var resume_button: Button = $PausePanel/Resume
@onready var restart_button: Button = $PausePanel/Restart
@onready var settings_button: Button = $PausePanel/Settings
@onready var map_button: Button = $PausePanel/Map

var _wave_spawner: WaveSpawner
var _settings: SettingsPanel
var _campaign_finale: CampaignFinale
var _displayed_gold: float = 0.0
var _target_gold: int = 0
var _speed: float = 1.0
var _kills: int = 0
var _elapsed: float = 0.0
var _hero_level: int = 1
var _last_hero_hp: float = 120.0
var _last_hero_max: float = 120.0
var _banner_tween: Tween
var _shards_gained: int = 0
var _shards_total: int = 0
var _disabled_until: Array[float] = []
var _flash_tween: Tween
var _lives_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wave_spawner = get_node_or_null(wave_spawner_path) as WaveSpawner
	_target_gold = Economy.gold
	_displayed_gold = float(_target_gold)
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.hero_health_changed.connect(_on_hero_health_changed)
	EventBus.hero_level_changed.connect(_on_hero_level_changed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.level_won.connect(_on_level_won)
	EventBus.level_lost.connect(_on_level_lost)
	EventBus.shards_awarded.connect(_on_shards_awarded)
	EventBus.tower_disabled.connect(_on_tower_disabled)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	speed_button.pressed.connect(_on_speed_pressed)
	pause_button.pressed.connect(_toggle_pause)
	continue_button.pressed.connect(_on_continue_pressed)
	resume_button.pressed.connect(_toggle_pause)
	restart_button.pressed.connect(_restart_level)
	settings_button.pressed.connect(_open_settings)
	map_button.pressed.connect(_on_continue_pressed)
	_settings = SETTINGS_SCENE.instantiate() as SettingsPanel
	add_child(_settings)
	_campaign_finale = CAMPAIGN_FINALE_SCENE.instantiate() as CampaignFinale
	add_child(_campaign_finale)
	_campaign_finale.closed.connect(_on_continue_pressed)
	pause_panel.visible = false
	victory_panel.visible = false
	shards_label.visible = false
	wave_banner.visible = false
	tower_alert_label.visible = false
	damage_flash.color.a = 0.0
	_refresh_all()

func _process(delta: float) -> void:
	if not get_tree().paused and GameManager.state != GameManager.State.WON and GameManager.state != GameManager.State.LOST:
		_elapsed += delta
	_displayed_gold = move_toward(_displayed_gold, float(_target_gold), delta * 300.0)
	gold_label.text = "Gold: %d" % roundi(_displayed_gold)
	if _wave_spawner:
		var display_wave: int = maxi(_wave_spawner.current_wave + 1, 1)
		var countdown_text: String = ""
		if _wave_spawner.waiting_for_next and _wave_spawner.current_wave >= 0:
			countdown_text = "  •  %ds" % ceili(maxf(_wave_spawner.countdown, 0.0))
		wave_label.text = "Wave %d / %d%s" % [display_wave, _wave_spawner.total_waves(), countdown_text]
		if _wave_spawner.waiting_for_next:
			next_wave_label.text = "Next: %s" % _wave_spawner.next_wave_summary()
		else:
			next_wave_label.text = "Enemies remaining: %d" % get_tree().get_nodes_in_group(&"enemies").size()
		var in_play: bool = GameManager.state == GameManager.State.BUILD or GameManager.state == GameManager.State.WAVE
		next_wave_button.disabled = not _wave_spawner.waiting_for_next or not in_play
	_update_tower_alert()

func _update_tower_alert() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var active: int = 0
	var remaining: float = 0.0
	for expiry: float in _disabled_until.duplicate():
		if expiry <= now:
			_disabled_until.erase(expiry)
			continue
		active += 1
		remaining = maxf(remaining, expiry - now)
	if active <= 0:
		tower_alert_label.visible = false
		return
	tower_alert_label.visible = true
	var noun: String = "tower" if active == 1 else "towers"
	tower_alert_label.text = "%d %s disabled  -  %.1fs" % [active, noun, remaining]

func _on_tower_disabled(_world_position: Vector3, duration: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_disabled_until.append(now + maxf(duration, 0.1))

func _on_enemy_reached_end(_enemy: Node3D, _damage: int) -> void:
	EventBus.camera_shake.emit(0.2)
	_flash_damage()

func _flash_damage() -> void:
	if _flash_tween:
		_flash_tween.kill()
	damage_flash.color.a = 0.28
	_flash_tween = create_tween()
	_flash_tween.tween_property(damage_flash, "color:a", 0.0, 0.45)
	if _lives_tween:
		_lives_tween.kill()
	lives_label.modulate = Color(1.0, 0.45, 0.45)
	_lives_tween = create_tween()
	_lives_tween.tween_property(lives_label, "modulate", Color.WHITE, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_game"):
		_toggle_pause()

func _on_lives_changed(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount

func _on_gold_changed(amount: int) -> void:
	_target_gold = amount

func _on_hero_health_changed(current: float, maximum: float) -> void:
	_last_hero_hp = current
	_last_hero_max = maximum
	hero_health_label.text = "Hero Lv.%d: %d / %d" % [_hero_level, ceili(current), roundi(maximum)]

func _on_hero_level_changed(new_level: int, _xp: int, _req: int) -> void:
	_hero_level = new_level
	hero_health_label.text = "Hero Lv.%d: %d / %d" % [_hero_level, ceili(_last_hero_hp), roundi(_last_hero_max)]

func _on_enemy_died(_enemy: Node3D, _reward: int) -> void:
	_kills += 1

func _on_wave_started(index: int) -> void:
	_refresh_all()
	var total: int = _wave_spawner.total_waves() if _wave_spawner else 0
	if _wave_spawner and _wave_spawner.is_current_wave_boss():
		_show_banner("⚠️ BOSS WAVE ⚠️")
	else:
		_show_banner("Wave %d / %d" % [index + 1, total])

func _show_banner(text: String) -> void:
	wave_banner.text = text
	wave_banner.visible = true
	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(1.12, 1.12)
	wave_banner.pivot_offset = wave_banner.size * 0.5
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(wave_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_interval(1.2)
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.45)
	_banner_tween.tween_callback(func() -> void: wave_banner.visible = false)

func _open_settings() -> void:
	if _settings:
		_settings.open()

func _on_next_wave_pressed() -> void:
	if get_tree().paused:
		return
	if _wave_spawner:
		_wave_spawner.call_next_wave()

func _on_speed_pressed() -> void:
	if get_tree().paused:
		return
	_speed = 2.0 if is_equal_approx(_speed, 1.0) else 1.0
	Engine.time_scale = _speed
	speed_button.text = "Speed: %.0fx" % _speed

func _toggle_pause() -> void:
	if GameManager.state == GameManager.State.WON or GameManager.state == GameManager.State.LOST:
		return
	pause_panel.visible = not pause_panel.visible
	get_tree().paused = pause_panel.visible
	pause_button.text = "Resume" if pause_panel.visible else "Pause"

func _on_level_won(stars: int) -> void:
	title_label.text = "Victory"
	stars_label.visible = true
	stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	stats_label.text = "Kills: %d    Waves: %d / %d\nTime: %s" % [
		_kills,
		_wave_spawner.total_waves() if _wave_spawner else 0,
		_wave_spawner.total_waves() if _wave_spawner else 0,
		_format_time(_elapsed),
	]
	_update_shards_label(true)
	victory_panel.visible = true
	pause_panel.visible = false
	get_tree().paused = false
	if SaveManager.current_level_id == "level_04" and SaveManager.campaign_complete():
		victory_panel.visible = false
		_campaign_finale.open()

func _on_level_lost() -> void:
	title_label.text = "Defeat"
	stars_label.visible = false
	shards_label.visible = false
	var reached: int = _wave_spawner.current_wave + 1 if _wave_spawner else 0
	stats_label.text = "Kills: %d    Waves: %d / %d\nTime: %s" % [
		_kills,
		maxi(reached, 0),
		_wave_spawner.total_waves() if _wave_spawner else 0,
		_format_time(_elapsed),
	]
	victory_panel.visible = true
	pause_panel.visible = false
	get_tree().paused = false

func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d" % [floori(float(total) / 60.0), total % 60]

func _on_shards_awarded(amount: int, total: int) -> void:
	_shards_gained = amount
	_shards_total = total

func _update_shards_label(won: bool) -> void:
	shards_label.visible = won
	if not won:
		return
	if _shards_gained > 0:
		shards_label.text = "New record!  +%d Crystal Shards  (Total: %d)" % [_shards_gained, _shards_total]
		shards_label.modulate = Color(0.55, 0.95, 1.0)
		shards_label.pivot_offset = shards_label.size * 0.5
		shards_label.scale = Vector2(1.15, 1.15)
		var tween := create_tween()
		tween.tween_property(shards_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		shards_label.text = "No new star record - no shards  (Total: %d)" % _shards_total
		shards_label.modulate = Color(0.65, 0.72, 0.8)

func _on_continue_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/WorldMap.tscn")

func _restart_level() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _refresh_all() -> void:
	_on_lives_changed(GameManager.lives)
	_on_gold_changed(Economy.gold)
	speed_button.text = "Speed: %.0fx" % _speed
