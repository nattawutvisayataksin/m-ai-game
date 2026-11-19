class_name SettingsPanel
extends CanvasLayer
## Reusable audio/display settings overlay. Works while the scene tree is paused.

signal closed

@onready var music_slider: HSlider = $Center/Panel/Margin/VBox/Music
@onready var sfx_slider: HSlider = $Center/Panel/Margin/VBox/Sfx
@onready var music_label: Label = $Center/Panel/Margin/VBox/MusicLabel
@onready var sfx_label: Label = $Center/Panel/Margin/VBox/SfxLabel
@onready var fullscreen_toggle: CheckButton = $Center/Panel/Margin/VBox/Fullscreen
@onready var back_button: Button = $Center/Panel/Margin/VBox/Back

func _ready() -> void:
	visible = false
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(close)
	_load_settings()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause_game"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	_load_settings()
	visible = true
	back_button.grab_focus()

func close() -> void:
	if not visible:
		return
	_save_settings()
	visible = false
	closed.emit()

func _load_settings() -> void:
	var music: float = clampf(float(SaveManager.get_setting(&"music", 0.8)), 0.0, 1.0)
	var sfx: float = clampf(float(SaveManager.get_setting(&"sfx", 0.8)), 0.0, 1.0)
	music_slider.set_value_no_signal(music)
	sfx_slider.set_value_no_signal(sfx)
	fullscreen_toggle.set_pressed_no_signal(bool(SaveManager.get_setting(&"fullscreen", false)))
	AudioDirector.set_music_volume(music)
	AudioPool.set_sfx_volume(sfx)
	_update_labels()
	_apply_fullscreen(fullscreen_toggle.button_pressed)

func _save_settings() -> void:
	SaveManager.set_setting(&"music", music_slider.value)
	SaveManager.set_setting(&"sfx", sfx_slider.value)
	SaveManager.set_setting(&"fullscreen", fullscreen_toggle.button_pressed)

func _on_music_changed(value: float) -> void:
	AudioDirector.set_music_volume(value)
	_update_labels()

func _on_sfx_changed(value: float) -> void:
	AudioPool.set_sfx_volume(value)
	_update_labels()

func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)

func _apply_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _update_labels() -> void:
	music_label.text = "Music: %d%%" % roundi(music_slider.value * 100.0)
	sfx_label.text = "SFX: %d%%" % roundi(sfx_slider.value * 100.0)
