class_name HealthBar
extends Sprite3D
## Billboard health bar drawn into a small runtime texture.

const BAR_WIDTH: int = 64
const BAR_HEIGHT: int = 8

var _image: Image
var _texture: ImageTexture

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	render_priority = 10
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pixel_size = 0.015
	_image = Image.create(BAR_WIDTH, BAR_HEIGHT, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	texture = _texture
	_draw_bar(1.0)
	visible = false

func set_ratio(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	_draw_bar(clamped)
	visible = clamped < 1.0 and clamped > 0.0

func _draw_bar(ratio: float) -> void:
	_image.fill(Color(0.05, 0.06, 0.09, 0.9))
	var filled: int = int(round(float(BAR_WIDTH) * ratio))
	if filled > 2:
		_image.fill_rect(Rect2i(1, 1, filled - 2, BAR_HEIGHT - 2), _bar_color(ratio))
	_texture.update(_image)

func _bar_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.25, 0.9, 0.35)
	if ratio > 0.25:
		return Color(1.0, 0.75, 0.15)
	return Color(0.95, 0.2, 0.2)
