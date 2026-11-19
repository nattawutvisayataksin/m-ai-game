class_name FloatingDamageNumbers
extends Node3D

@export var number_scene: PackedScene
@export var pool_size: int = 32

var _pool: Array[Label3D] = []

func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.heal_dealt.connect(_on_heal_dealt)
	EventBus.tower_disabled.connect(_on_tower_disabled)
	for index: int in pool_size:
		var label := _create_label()
		_pool.append(label)

func _on_damage_dealt(world_position: Vector3, amount: float) -> void:
	var label := _get_label()
	if label == null:
		return
	label.global_position = world_position
	var is_heavy: bool = amount >= 25.0
	label.text = str(roundi(amount))
	label.modulate = Color(1.0, 0.35, 0.1) if is_heavy else Color(1.0, 0.9, 0.3)
	label.scale = Vector3.ONE * (1.35 if is_heavy else 1.0)
	label.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.set_parallel(false)
	tween.tween_callback(_release.bind(label))

func _on_heal_dealt(world_position: Vector3, amount: float) -> void:
	pop_text(world_position, "+%d" % roundi(amount), Color(0.45, 1.0, 0.6), 0.9)

func _on_tower_disabled(world_position: Vector3, _duration: float) -> void:
	pop_text(world_position, "DISABLED", Color(0.8, 0.5, 1.0), 1.0)

func pop_text(world_position: Vector3, text: String, color: Color = Color(1.0, 0.85, 0.2), scale_mult: float = 1.0) -> void:
	var label := _get_label()
	if label == null:
		return
	label.global_position = world_position
	label.text = text
	label.modulate = color
	label.scale = Vector3.ONE * scale_mult
	label.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.2, 0.75)
	tween.tween_property(label, "modulate:a", 0.0, 0.75)
	tween.set_parallel(false)
	tween.tween_callback(_release.bind(label))

func _create_label() -> Label3D:
	var label: Label3D = number_scene.instantiate() as Label3D if number_scene else Label3D.new()
	add_child(label)
	label.visible = false
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label

func _get_label() -> Label3D:
	for label: Label3D in _pool:
		if not label.visible:
			return label
	return null

func _release(label: Label3D) -> void:
	label.visible = false
	label.modulate.a = 1.0
