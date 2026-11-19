class_name TutorialHints
extends CanvasLayer
## Contextual first-time hints for the opening level.

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Margin/Label

var _tween: Tween
var _built_hint: bool = false
var _leak_hint: bool = false
var _hero_hint: bool = false
var _wave_hint: bool = false

func _ready() -> void:
	panel.modulate.a = 0.0
	if bool(SaveManager.get_setting(&"tutorial_done", false)):
		queue_free()
		return
	EventBus.tower_built.connect(_on_tower_built)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)
	EventBus.hero_level_changed.connect(_on_hero_level_changed)
	EventBus.level_won.connect(_on_level_won)
	show_hint("START HERE  •  Click a cyan ring, then choose a tower.\nPress Next Wave when ready. Meteor auto-aims (1); reinforcements (2).\nCamera: WASD / screen edge to pan, Q/E to rotate, wheel to zoom.", 16.0)

func show_hint(text: String, hold: float = 4.5) -> void:
	if not is_inside_tree():
		return
	label.text = text
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	_tween.tween_interval(hold)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.4)

func _on_tower_built(_world_position: Vector3) -> void:
	if _built_hint:
		return
	_built_hint = true
	show_hint("Nice! Towers fire on their own.\nArchers and Mages hit flying enemies - Cannons cannot.", 6.0)

func _on_wave_started(index: int) -> void:
	if _wave_hint or index > 0:
		return
	_wave_hint = true
	show_hint("Enemies follow the path. Stop them before they reach the gate!", 5.5)

func _on_enemy_reached_end(_enemy: Node3D, _damage: int) -> void:
	if _leak_hint:
		return
	_leak_hint = true
	show_hint("An enemy slipped through! Build closer to the lane and upgrade your towers.", 6.0)

func _on_hero_level_changed(level: int, _xp: int, _required: int) -> void:
	if _hero_hint or level < 2:
		return
	_hero_hint = true
	show_hint("Your hero leveled up!\nMeteor auto-aims at the largest enemy group (1). Reinforcements arrive with 2.", 6.0)

func _on_level_won(_stars: int) -> void:
	SaveManager.set_setting(&"tutorial_done", true)
