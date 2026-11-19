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
		var camera := get_viewport().get_camera_3d()
		if camera:
			var mouse_pos := get_viewport().get_mouse_position()
			_hero.use_meteor(_screen_to_world(mouse_pos, camera))
	elif event.is_action_pressed(&"ability_reinforcements"):
		_hero.use_reinforcements()

func _meteor_pressed() -> void:
	if _hero:
		_hero.use_meteor(_hero.global_position)

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

func _screen_to_world(screen_position: Vector2, camera: Camera3D) -> Vector3:
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	return result["position"] as Vector3 if result.has("position") else _hero.global_position
