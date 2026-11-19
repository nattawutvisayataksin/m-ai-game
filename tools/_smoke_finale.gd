extends Node

func _ready() -> void:
	var original: Dictionary = SaveManager.data.duplicate(true)
	var original_level_id: String = SaveManager.current_level_id
	SaveManager.data["stars"]["level_04"] = 3
	SaveManager.data["shards"] = 4
	SaveManager.data["settings"].erase("campaign_bonus_claimed")
	SaveManager.current_level_id = "level_04"
	var hud := (load("res://scenes/ui/GameHUD.tscn") as PackedScene).instantiate() as GameHUD
	add_child(hud)
	await get_tree().process_frame
	EventBus.level_won.emit(3)
	await get_tree().process_frame
	var finale: CampaignFinale = hud._campaign_finale
	print("SMOKE finale_open=%s victory_hidden=%s bonus=%d shards=%d stats=%s" % [
		str(finale.visible),
		str(not hud.victory_panel.visible),
		CampaignFinale.CAMPAIGN_BONUS if finale.bonus_label.visible else 0,
		SaveManager.get_shards(),
		finale.stats_label.text,
	])
	var second_claim: int = finale._claim_bonus()
	finale.open()
	print("SMOKE finale_second_claim=%d bonus_visible=%s shards=%d" % [
		second_claim,
		str(finale.bonus_label.visible),
		SaveManager.get_shards(),
	])
	SaveManager.data = original
	SaveManager.current_level_id = original_level_id
	SaveManager.save_game()
	hud.queue_free()
	print("SMOKE restored campaign_bonus_claimed=%s" % str(SaveManager.get_setting(&"campaign_bonus_claimed", false)))
	print("SMOKE done")
	get_tree().quit()
