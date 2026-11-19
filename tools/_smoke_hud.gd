extends Node

func _ready() -> void:
	var hud := (load("res://scenes/ui/GameHUD.tscn") as PackedScene).instantiate() as GameHUD
	add_child(hud)
	await get_tree().process_frame
	print("SMOKE hud_initial alert_visible=%s flash=%.2f" % [
		str(hud.tower_alert_label.visible),
		hud.damage_flash.color.a,
	])

	EventBus.tower_disabled.emit(Vector3.ZERO, 2.5)
	EventBus.tower_disabled.emit(Vector3.ZERO, 1.0)
	await get_tree().process_frame
	print("SMOKE hud_two_alerts visible=%s text=%s" % [
		str(hud.tower_alert_label.visible),
		hud.tower_alert_label.text,
	])

	await get_tree().create_timer(1.3).timeout
	print("SMOKE hud_one_alert visible=%s text=%s" % [
		str(hud.tower_alert_label.visible),
		hud.tower_alert_label.text,
	])

	EventBus.enemy_reached_end.emit(null, 1)
	await get_tree().process_frame
	print("SMOKE hud_leak flash=%.2f lives_color=%s" % [
		hud.damage_flash.color.a,
		str(hud.lives_label.modulate),
	])

	await get_tree().create_timer(1.6).timeout
	print("SMOKE hud_settled alert_visible=%s flash=%.2f lives_color=%s" % [
		str(hud.tower_alert_label.visible),
		hud.damage_flash.color.a,
		str(hud.lives_label.modulate),
	])
	print("SMOKE done")
	get_tree().quit()
