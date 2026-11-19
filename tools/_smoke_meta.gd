extends Node

func _ready() -> void:
	var original: Dictionary = SaveManager.data.duplicate(true)
	SaveManager.data["shards"] = 10
	SaveManager.data["upgrades"] = {"vanguard": 1, "fortress": 0, "treasury": 2}
	print("SMOKE initial shards=%d vanguard=%d fortress=%d treasury=%d" % [
		SaveManager.get_shards(),
		MetaProgression.level_of(&"vanguard"),
		MetaProgression.level_of(&"fortress"),
		MetaProgression.level_of(&"treasury"),
	])
	print("SMOKE multipliers dmg=%.2f lives=%d gold=%d" % [
		MetaProgression.tower_damage_multiplier(),
		MetaProgression.bonus_start_lives(),
		MetaProgression.bonus_start_gold(),
	])

	var fortress_buy: bool = MetaProgression.buy(&"fortress")
	print("SMOKE buy_fortress ok=%s shards=%d level=%d next_cost=%d" % [
		str(fortress_buy),
		SaveManager.get_shards(),
		MetaProgression.level_of(&"fortress"),
		MetaProgression.next_cost(&"fortress"),
	])

	var vanguard_buy: bool = MetaProgression.buy(&"vanguard")
	print("SMOKE buy_vanguard ok=%s shards=%d level=%d dmg=%.2f" % [
		str(vanguard_buy),
		SaveManager.get_shards(),
		MetaProgression.level_of(&"vanguard"),
		MetaProgression.tower_damage_multiplier(),
	])

	var poor_buy: bool = MetaProgression.buy(&"treasury")
	print("SMOKE buy_treasury_no_funds ok=%s shards=%d treasury=%d" % [
		str(poor_buy),
		SaveManager.get_shards(),
		MetaProgression.level_of(&"treasury"),
	])

	SaveManager.data["upgrades"]["treasury"] = 3
	print("SMOKE treasury_maxed=%s next_cost=%d gold=%d" % [
		str(MetaProgression.is_maxed(&"treasury")),
		MetaProgression.next_cost(&"treasury"),
		MetaProgression.bonus_start_gold(),
	])
	SaveManager.data["upgrades"]["treasury"] = 2

	var level_data: LevelData = load("res://data/levels/Level01.tres") as LevelData
	GameManager.start_level(level_data)
	print("SMOKE start_level base_lives=%d final_lives=%d/%d base_gold=%d final_gold=%d" % [
		level_data.start_lives,
		GameManager.lives,
		GameManager.max_lives,
		level_data.start_gold,
		Economy.gold,
	])

	var panel := (load("res://scenes/ui/BlessingsPanel.tscn") as PackedScene).instantiate() as BlessingsPanel
	add_child(panel)
	await get_tree().process_frame
	panel.open()
	await get_tree().process_frame
	print("SMOKE panel visible=%s shards_label=%s" % [str(panel.visible), panel.shards_label.text])
	print("SMOKE panel bonuses=%s" % panel.bonuses_label.text)
	for index: int in MetaProgression.TRACKS.size():
		print("SMOKE panel_row%d name=%s level=%s button=%s disabled=%s" % [
			index,
			MetaProgression.TRACK_NAMES[index],
			panel.level_labels[index].text,
			panel.buy_buttons[index].text,
			str(panel.buy_buttons[index].disabled),
		])
	panel.close()
	print("SMOKE panel_closed=%s" % str(not panel.visible))
	panel.queue_free()

	var map := (load("res://scenes/ui/WorldMap.tscn") as PackedScene).instantiate() as WorldMap
	add_child(map)
	await get_tree().process_frame
	print("SMOKE worldmap shards_label=%s blessings_visible=%s" % [
		map.shards_label.text,
		str(map._blessings.visible),
	])
	print("SMOKE worldmap progress=%s" % map.progress_label.text)
	print("SMOKE worldmap buttons=%d level4=%s" % [
		map.level_buttons.size(),
		map.level_buttons[3].text.replace("\n", " | "),
	])
	map._open_blessings()
	print("SMOKE worldmap_open_blessings visible=%s" % str(map._blessings.visible))
	map.queue_free()
	await get_tree().process_frame

	SaveManager.current_level_id = "level_01"
	SaveManager.data["stars"]["level_01"] = 0
	var hud := (load("res://scenes/ui/GameHUD.tscn") as PackedScene).instantiate() as GameHUD
	add_child(hud)
	await get_tree().process_frame
	var shards_before_wins: int = SaveManager.get_shards()
	EventBus.level_won.emit(2)
	print("SMOKE win_2stars shards=%d (+%d) stars=%d" % [
		SaveManager.get_shards(),
		SaveManager.get_shards() - shards_before_wins,
		SaveManager.get_stars("level_01"),
	])
	print("SMOKE hud_new_record text=%s visible=%s" % [hud.shards_label.text, str(hud.shards_label.visible)])
	var shards_before_replay: int = SaveManager.get_shards()
	EventBus.level_won.emit(2)
	print("SMOKE win_same_record shards=%d (+%d)" % [
		SaveManager.get_shards(),
		SaveManager.get_shards() - shards_before_replay,
	])
	print("SMOKE hud_no_record text=%s" % hud.shards_label.text)
	var shards_before_better: int = SaveManager.get_shards()
	EventBus.level_won.emit(3)
	print("SMOKE win_3stars shards=%d (+%d) stars=%d" % [
		SaveManager.get_shards(),
		SaveManager.get_shards() - shards_before_better,
		SaveManager.get_stars("level_01"),
	])
	hud.queue_free()
	SaveManager.current_level_id = ""

	SaveManager.data = original
	SaveManager.save_game()
	print("SMOKE restored shards=%d" % SaveManager.get_shards())
	print("SMOKE done")
	get_tree().quit()
