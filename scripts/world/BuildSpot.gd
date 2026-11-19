class_name BuildSpot
extends Area3D
## Clickable pedestal for building, upgrading, and selling towers.

@onready var ring: MeshInstance3D = $Ring

@export var upgrade_burst_scene: PackedScene

var tower: Tower = null

func _ready() -> void:
	input_ray_pickable = true
	ring.visible = tower == null
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if tower:
			EventBus.tower_selected.emit(tower)
		else:
			EventBus.build_spot_clicked.emit(self)
		get_viewport().set_input_as_handled()

func build(tower_data: TowerData) -> bool:
	if tower != null or tower_data == null or tower_data.tower_scene == null:
		return false
	if not Economy.spend(tower_data.cost):
		return false
	_place(tower_data, tower_data.cost, Tower.TargetMode.FIRST)
	return true

func upgrade(next: TowerData) -> bool:
	if tower == null or next == null or next.tower_scene == null:
		return false
	if not Economy.spend(next.cost):
		return false
	var spent: int = tower.total_spent + next.cost
	var mode: Tower.TargetMode = tower.target_mode
	tower.queue_free()
	_place(next, spent, mode)
	return true

func sell() -> void:
	if tower == null:
		return
	Economy.add(int(tower.total_spent * tower.data.sell_ratio))
	tower.queue_free()
	tower = null
	ring.visible = true

func _place(tower_data: TowerData, spent: int, mode: Tower.TargetMode) -> void:
	if tower_data.tower_scene == null:
		return
	var placed := tower_data.tower_scene.instantiate() as Tower
	placed.data = tower_data
	placed.total_spent = spent
	placed.target_mode = mode
	add_child(placed)
	tower = placed
	ring.visible = false
	EventBus.tower_built.emit(placed.global_position)
	placed.scale = Vector3.ONE * 0.6
	var tw := placed.create_tween()
	tw.tween_property(placed, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if upgrade_burst_scene:
		var burst := upgrade_burst_scene.instantiate() as Node3D
		add_child(burst)
		burst.position = Vector3.UP * 0.5

func _on_hover(is_over: bool) -> void:
	ring.visible = is_over and tower == null
