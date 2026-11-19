class_name BlessingsPanel
extends CanvasLayer
## Permanent upgrade shop opened from the world map.

signal closed

@onready var shards_label: Label = $Center/Panel/Margin/VBox/Shards
@onready var bonuses_label: Label = $Center/Panel/Margin/VBox/Bonuses
@onready var status_label: Label = $Center/Panel/Margin/VBox/Status
@onready var back_button: Button = $Center/Panel/Margin/VBox/Back
@onready var level_labels: Array[Label] = [
	$Center/Panel/Margin/VBox/Vanguard/Level,
	$Center/Panel/Margin/VBox/Fortress/Level,
	$Center/Panel/Margin/VBox/Treasury/Level,
]
@onready var buy_buttons: Array[Button] = [
	$Center/Panel/Margin/VBox/Vanguard/Buy,
	$Center/Panel/Margin/VBox/Fortress/Buy,
	$Center/Panel/Margin/VBox/Treasury/Buy,
]

func _ready() -> void:
	visible = false
	status_label.text = ""
	for index: int in buy_buttons.size():
		buy_buttons[index].pressed.connect(_buy_pressed.bind(index))
	back_button.pressed.connect(close)
	MetaProgression.changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause_game"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	status_label.text = ""
	_refresh()
	back_button.grab_focus()

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _buy_pressed(index: int) -> void:
	var track: StringName = MetaProgression.TRACKS[index]
	if MetaProgression.buy(track):
		status_label.text = "%s upgraded to level %d" % [
			MetaProgression.TRACK_NAMES[index],
			MetaProgression.level_of(track),
		]
	else:
		status_label.text = "Not enough crystal shards"
	_refresh()

func _refresh() -> void:
	shards_label.text = "Crystal Shards: %d" % SaveManager.get_shards()
	var damage_bonus: int = roundi((MetaProgression.tower_damage_multiplier() - 1.0) * 100.0)
	bonuses_label.text = "Active: +%d%% damage  |  +%d lives  |  +%d gold" % [
		damage_bonus,
		MetaProgression.bonus_start_lives(),
		MetaProgression.bonus_start_gold(),
	]
	for index: int in MetaProgression.TRACKS.size():
		var track: StringName = MetaProgression.TRACKS[index]
		level_labels[index].text = "%d / %d" % [MetaProgression.level_of(track), MetaProgression.MAX_LEVEL]
		var button: Button = buy_buttons[index]
		if MetaProgression.is_maxed(track):
			button.text = "MAX"
			button.disabled = true
		else:
			button.text = "%d shards" % MetaProgression.next_cost(track)
			button.disabled = not MetaProgression.can_buy(track)
