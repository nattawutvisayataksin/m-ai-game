class_name RadialBuildMenu
extends CanvasLayer

@export var tower_options: Array[TowerData] = []

@onready var panel: Control = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var buttons: Array[Button] = [$Panel/VBox/Tower1, $Panel/VBox/Tower2, $Panel/VBox/Tower3, $Panel/VBox/Tower4]
@onready var upgrade_button: Button = $Panel/VBox/Upgrade
@onready var mode_button: Button = $Panel/VBox/Mode
@onready var sell_button: Button = $Panel/VBox/Sell

var _spot: BuildSpot
var _tower: Tower
var _setting_rally: bool = false

func _ready() -> void:
	visible = false
	EventBus.build_spot_clicked.connect(_on_spot_clicked)
	EventBus.tower_selected.connect(_on_tower_selected)
	EventBus.gold_changed.connect(_on_gold_changed)
	for index: int in buttons.size():
		buttons[index].pressed.connect(_build_pressed.bind(index))
	upgrade_button.pressed.connect(_upgrade_pressed)
	mode_button.pressed.connect(_mode_pressed)
	sell_button.pressed.connect(_sell_pressed)

func _process(_delta: float) -> void:
	if visible and _spot != null and _tower == null:
		_refresh_build_buttons()

func _on_spot_clicked(spot: Node3D) -> void:
	_spot = spot as BuildSpot
	_tower = null
	_show_build_menu()

func _on_tower_selected(tower_node: Node3D) -> void:
	_tower = tower_node as Tower
	_spot = _tower.get_parent() as BuildSpot if _tower else null
	_show_tower_menu()

func _on_gold_changed(_amount: int) -> void:
	if not visible:
		return
	if _tower:
		_refresh_tower_buttons()
	else:
		_refresh_build_buttons()

func _show_build_menu() -> void:
	visible = _spot != null
	title.text = "Build Tower"
	upgrade_button.visible = false
	mode_button.visible = false
	sell_button.visible = false
	_refresh_build_buttons()

func _show_tower_menu() -> void:
	visible = _tower != null
	title.text = _tower.data.display_name if _tower else "Tower"
	for button: Button in buttons:
		button.visible = false
	upgrade_button.visible = true
	mode_button.visible = true
	sell_button.visible = true
	_refresh_tower_buttons()

func _refresh_build_buttons() -> void:
	for index: int in buttons.size():
		var button: Button = buttons[index]
		button.visible = index < tower_options.size()
		if index >= tower_options.size():
			continue
		var data: TowerData = tower_options[index]
		button.text = "%s\n$%d" % [data.display_name, data.cost]
		button.tooltip_text = _tower_tooltip(data)
		button.disabled = not Economy.can_afford(data.cost)

func _tower_tooltip(data: TowerData) -> String:
	if data == null:
		return ""
	var damage_type: String = String(TowerData.DamageType.keys()[data.damage_type]).capitalize()
	var dps: float = (data.damage_min + data.damage_max) * 0.5 * data.fire_rate
	var lines: Array[String] = [
		data.display_name,
		"Damage: %.0f-%.0f (%s)" % [data.damage_min, data.damage_max, damage_type],
		"Range: %.1f m   Rate: %.2f/s   DPS: %.1f" % [data.attack_range, data.fire_rate, dps],
	]
	if data.aoe_radius > 0.0:
		lines.append("Splash radius: %.1f m" % data.aoe_radius)
	if data.slow_amount > 0.0:
		lines.append("Slow: %d%% for %.1f s" % [roundi(data.slow_amount * 100.0), data.slow_duration])
	if data.poison_dps > 0.0:
		lines.append("Poison: %.1f dps for %.1f s" % [data.poison_dps, data.poison_duration])
	if not data.can_hit_flying:
		lines.append("Cannot target flying enemies")
	return "\n".join(lines)

func _refresh_tower_buttons() -> void:
	if _tower == null:
		return
	if _tower is Barracks:
		mode_button.text = "Set Rally Point"
	else:
		mode_button.text = "Target: %s" % Tower.TargetMode.keys()[_tower.target_mode]
	sell_button.text = "Sell $%d" % int(_tower.total_spent * _tower.data.sell_ratio)
	var upgrades: Array[TowerData] = _tower.data.upgrade_to
	upgrade_button.disabled = upgrades.is_empty() or not Economy.can_afford(upgrades[0].cost)
	upgrade_button.text = "Upgrade $%d" % upgrades[0].cost if not upgrades.is_empty() else "Max Level"

func _build_pressed(index: int) -> void:
	if _spot == null or _tower != null or index >= tower_options.size():
		return
	if _spot.build(tower_options[index]):
		visible = false

func _upgrade_pressed() -> void:
	if _tower == null or _tower.data.upgrade_to.is_empty():
		return
	var options: Array[TowerData] = _tower.data.upgrade_to
	if options.size() == 1:
		if _spot.upgrade(options[0]):
			visible = false
		return
	# Two upgrade branches are shown directly as the first two choices.
	buttons[0].visible = true
	buttons[1].visible = true
	buttons[0].text = "%s\n$%d" % [options[0].display_name, options[0].cost]
	buttons[1].text = "%s\n$%d" % [options[1].display_name, options[1].cost]
	buttons[0].disabled = not Economy.can_afford(options[0].cost)
	buttons[1].disabled = not Economy.can_afford(options[1].cost)
	for index: int in 2:
		var callback: Callable = _branch_pressed.bind(index)
		if not buttons[index].pressed.is_connected(callback):
			buttons[index].pressed.connect(callback, CONNECT_ONE_SHOT)

func _branch_pressed(index: int) -> void:
	if _spot != null and _tower != null and index < _tower.data.upgrade_to.size():
		if _spot.upgrade(_tower.data.upgrade_to[index]):
			visible = false

func _mode_pressed() -> void:
	if _tower is Barracks:
		_setting_rally = true
		visible = false
	elif _tower:
		_tower.cycle_target_mode()
		_refresh_tower_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if not _setting_rally:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera := get_viewport().get_camera_3d()
		if camera and _tower is Barracks:
			var mouse_pos := (event as InputEventMouseButton).position
			var origin := camera.project_ray_origin(mouse_pos)
			var end := origin + camera.project_ray_normal(mouse_pos) * 1000.0
			var query := PhysicsRayQueryParameters3D.create(origin, end)
			query.collide_with_areas = false
			query.collision_mask = 1
			var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.has("position"):
				(_tower as Barracks).set_rally_point(hit["position"] as Vector3)
		_setting_rally = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_setting_rally = false

func _sell_pressed() -> void:
	if _spot:
		_spot.sell()
	visible = false
