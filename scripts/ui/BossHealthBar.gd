class_name BossHealthBar
extends Control
## Top-center boss status bar driven by EventBus boss signals.

const FADE_IN_SECONDS: float = 0.25
const DEATH_HOLD_SECONDS: float = 0.9
const DEATH_FADE_SECONDS: float = 0.35
const LOW_HEALTH_RATIO: float = 0.3

@onready var name_label: Label = $Container/VBox/Name
@onready var health_bar: ProgressBar = $Container/VBox/Health
@onready var health_text: Label = $Container/VBox/HealthText

var _boss: Enemy
var _boss_name: String = "Boss"
var _tween: Tween

func _ready() -> void:
	visible = false
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_died.connect(_on_boss_died)

func _on_boss_spawned(boss: Node3D) -> void:
	var enemy := boss as Enemy
	if enemy == null or enemy.data == null:
		return
	_boss = enemy
	_boss_name = enemy.data.display_name
	name_label.text = _boss_name
	_set_health(enemy.hp, enemy.max_hp)
	_show()
	EventBus.camera_shake.emit(0.35)

func _on_boss_health_changed(current: float, maximum: float) -> void:
	if _boss == null or _boss.is_dead:
		return
	_set_health(current, maximum)

func _on_boss_died(boss: Node3D) -> void:
	if _boss == null or _boss != boss:
		return
	_boss = null
	health_bar.value = 0.0
	health_text.text = "Slain"
	_restart_tween()
	_tween.tween_interval(DEATH_HOLD_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, DEATH_FADE_SECONDS)
	_tween.tween_callback(_finish_hide)

func _set_health(current: float, maximum: float) -> void:
	var ratio: float = clampf(current / maxf(maximum, 0.001), 0.0, 1.0)
	health_bar.value = ratio * 100.0
	health_text.text = "%d / %d" % [ceili(maxf(current, 0.0)), roundi(maximum)]
	var low: bool = ratio <= LOW_HEALTH_RATIO
	var enraged: bool = ratio <= 0.5
	health_bar.modulate = Color(1.0, 0.45, 0.25) if low else Color.WHITE
	name_label.text = _boss_name + "  -  ENRAGED" if enraged else _boss_name
	name_label.modulate = Color(1.0, 0.45, 0.25) if enraged else Color.WHITE

func _show() -> void:
	visible = true
	modulate.a = 0.0
	_restart_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS)

func _finish_hide() -> void:
	visible = false
	modulate.a = 1.0

func _restart_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
