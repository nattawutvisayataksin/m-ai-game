extends Node3D
## CameraRig -> Pitch -> Camera3D.

@export var pan_speed: float = 14.0
@export var zoom_min: float = 12.0
@export var zoom_max: float = 40.0
@export var zoom_step: float = 2.5
@export var bounds: Rect2 = Rect2(-25, -25, 50, 50)
@export var edge_margin: int = 12
@export var viewport_padding_factor: float = 0.28

@onready var cam: Camera3D = $Pitch/Camera3D

var _zoom: float = 25.0
var _target_zoom: float = 25.0
var _yaw_target: float = 0.0
var _shake: float = 0.0

func _ready() -> void:
	_yaw_target = rotation.y
	$Pitch.rotation_degrees.x = -55.0
	cam.fov = 35.0
	EventBus.camera_shake.connect(shake)

func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

func set_level_bounds(rect: Rect2) -> void:
	bounds = rect
	_clamp_to_bounds()

func _unhandled_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.pressed:
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = maxf(zoom_min, _target_zoom - zoom_step)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = minf(zoom_max, _target_zoom + zoom_step)
	if event.is_action_pressed(&"cam_rotate_left"):
		_yaw_target += deg_to_rad(45.0)
	elif event.is_action_pressed(&"cam_rotate_right"):
		_yaw_target -= deg_to_rad(45.0)

func _process(raw_delta: float) -> void:
	var delta: float = raw_delta / maxf(Engine.time_scale, 0.01)
	var input_vector := Vector2.ZERO
	if InputMap.has_action(&"cam_left") and InputMap.has_action(&"cam_right") and InputMap.has_action(&"cam_forward") and InputMap.has_action(&"cam_back"):
		input_vector = Input.get_vector(&"cam_left", &"cam_right", &"cam_forward", &"cam_back")
	var mouse_position := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size
	if mouse_position.x < edge_margin:
		input_vector.x = -1.0
	elif mouse_position.x > viewport_size.x - edge_margin:
		input_vector.x = 1.0
	if mouse_position.y < edge_margin:
		input_vector.y = -1.0
	elif mouse_position.y > viewport_size.y - edge_margin:
		input_vector.y = 1.0
	var direction := transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		position += direction.normalized() * pan_speed * (_zoom / 25.0) * delta
	_clamp_to_bounds()
	_zoom = lerpf(_zoom, _target_zoom, 1.0 - exp(-10.0 * delta))
	cam.position.z = _zoom
	rotation.y = lerp_angle(rotation.y, _yaw_target, 1.0 - exp(-8.0 * delta))
	if _shake > 0.0:
		cam.h_offset = randf_range(-1.0, 1.0) * _shake
		cam.v_offset = randf_range(-1.0, 1.0) * _shake
		_shake = move_toward(_shake, 0.0, delta * 1.5)
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0

func _clamp_to_bounds() -> void:
	var padding: float = maxf(_zoom * viewport_padding_factor, 0.0)
	var min_x: float = bounds.position.x + padding
	var max_x: float = bounds.end.x - padding
	var min_z: float = bounds.position.y + padding
	var max_z: float = bounds.end.y - padding
	if min_x > max_x:
		var center_x: float = bounds.get_center().x
		min_x = center_x
		max_x = center_x
	if min_z > max_z:
		var center_z: float = bounds.get_center().y
		min_z = center_z
		max_z = center_z
	position.x = clampf(position.x, min_x, max_x)
	position.z = clampf(position.z, min_z, max_z)
