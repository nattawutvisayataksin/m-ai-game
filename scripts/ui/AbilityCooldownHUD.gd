class_name AbilityCooldownHUD
extends CanvasLayer

@export var hero_path: NodePath
@onready var meteor_button: Button = $Panel/Meteor
@onready var reinforcements_button: Button = $Panel/Reinforcements
@onready var meteor_fill: ProgressBar = $Panel/Meteor/Cooldown
@onready var reinforcements_fill: ProgressBar = $Panel/Reinforcements/Cooldown

var _hero: Hero

func _ready() -> void:
	meteor_button.pressed.connect(_meteor_pressed)
	reinforcements_button.pressed.connect(_reinforcements_pressed)
	_hero = get_node_or_null(hero_path) as Hero
	if _hero:
		_hero.skill_cooldown_changed.connect(_on_skill_cooldown_changed)

func _process(_delta: float) -> void:
	if _hero == null:
		_hero = get_node_or_null(hero_path) as Hero
		if _hero:
			_hero.skill_cooldown_changed.connect(_on_skill_cooldown_changed)

func _unhandled_input(event: InputEvent) -> void:
	if _hero == null:
		return
	if event.is_action_pressed(&"ability_meteor"):
		_hero.use_meteor(_hero.best_meteor_target())
	elif event.is_action_pressed(&"ability_reinforcements"):
		_hero.use_reinforcements()

func _meteor_pressed() -> void:
	if _hero:
		_hero.use_meteor(_hero.best_meteor_target())

func _reinforcements_pressed() -> void:
	if _hero:
		_hero.use_reinforcements()

func _on_skill_cooldown_changed(skill_index: int, remaining: float, duration: float) -> void:
	var ratio: float = remaining / duration if duration > 0.0 else 0.0
	if skill_index == 0:
		meteor_fill.value = ratio * 100.0
		meteor_button.disabled = remaining > 0.0
	else:
		reinforcements_fill.value = ratio * 100.0
		reinforcements_button.disabled = remaining > 0.0
