extends Node

func _ready() -> void:
	var original: Dictionary = SaveManager.data.duplicate(true)
	SaveManager.data["settings"].erase("tutorial_done")

	var hints := (load("res://scenes/ui/TutorialHints.tscn") as PackedScene).instantiate() as TutorialHints
	add_child(hints)
	await get_tree().process_frame
	print("SMOKE hint_welcome %s" % hints.label.text.replace("\n", " | "))

	EventBus.tower_built.emit(Vector3.ZERO)
	await get_tree().process_frame
	print("SMOKE hint_build %s" % hints.label.text.replace("\n", " | "))

	EventBus.wave_started.emit(0)
	await get_tree().process_frame
	print("SMOKE hint_wave %s" % hints.label.text.replace("\n", " | "))

	EventBus.enemy_reached_end.emit(null, 1)
	await get_tree().process_frame
	print("SMOKE hint_leak %s" % hints.label.text.replace("\n", " | "))

	EventBus.hero_level_changed.emit(2, 0, 125)
	await get_tree().process_frame
	print("SMOKE hint_hero %s" % hints.label.text.replace("\n", " | "))

	EventBus.level_won.emit(2)
	await get_tree().process_frame
	print("SMOKE tutorial_done=%s" % str(SaveManager.get_setting(&"tutorial_done", false)))

	hints.queue_free()
	await get_tree().process_frame
	var second := (load("res://scenes/ui/TutorialHints.tscn") as PackedScene).instantiate() as TutorialHints
	add_child(second)
	await get_tree().process_frame
	print("SMOKE repeat_suppressed freed=%s" % str(not is_instance_valid(second)))
	if is_instance_valid(second):
		second.queue_free()

	SaveManager.data = original
	SaveManager.save_game()
	await get_tree().process_frame
	print("SMOKE restored tutorial_done=%s" % str(SaveManager.get_setting(&"tutorial_done", false)))
	AudioDirector.stop_all_audio()
	await get_tree().process_frame
	print("SMOKE done")
	get_tree().quit()
