class_name CampaignFinale
extends Control
## End-of-campaign epilogue shown once the last level is cleared.

signal closed

const CAMPAIGN_BONUS: int = 10
const LEVEL_COUNT: int = 4

@onready var panel: Panel = $Panel
@onready var stats_label: Label = $Panel/Margin/VBox/Stats
@onready var bonus_label: Label = $Panel/Margin/VBox/Bonus
@onready var close_button: Button = $Panel/Margin/VBox/Continue

var _tween: Tween

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func open() -> void:
	var awarded: int = _claim_bonus()
	_update_stats(awarded)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	_tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _claim_bonus() -> int:
	if bool(SaveManager.get_setting(&"campaign_bonus_claimed", false)):
		return 0
	SaveManager.set_setting(&"campaign_bonus_claimed", true)
	SaveManager.add_shards(CAMPAIGN_BONUS)
	EventBus.campaign_completed.emit()
	return CAMPAIGN_BONUS

func _update_stats(awarded: int) -> void:
	var stars: int = 0
	for index: int in LEVEL_COUNT:
		stars += SaveManager.get_stars("level_%02d" % (index + 1))
	var blessings: int = 0
	for track: StringName in MetaProgression.TRACKS:
		blessings += MetaProgression.level_of(track)
	stats_label.text = "Total stars: %d / %d      Crystal Shards: %d      Blessings: %d / %d" % [
		stars,
		LEVEL_COUNT * 3,
		SaveManager.get_shards(),
		blessings,
		MetaProgression.TRACKS.size() * MetaProgression.MAX_LEVEL,
	]
	bonus_label.visible = awarded > 0
	if awarded > 0:
		bonus_label.text = "Campaign bonus: +%d Crystal Shards" % awarded
