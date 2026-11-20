extends Node
## Temporary visual-check helper: renders each level to .godot/captures.

const LEVELS: Array[Array] = [
	["level01", "res://scenes/levels/Level01.tscn"],
	["level02", "res://scenes/levels/Level02.tscn"],
	["level03", "res://scenes/levels/Level03.tscn"],
	["level04", "res://scenes/levels/Level04.tscn"],
]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/captures"))
	for entry: Array in LEVELS:
		var packed := load(String(entry[1])) as PackedScene
		if packed == null:
			continue
		var level := packed.instantiate()
		add_child(level)
		for child: Node in level.get_children():
			if child is CanvasLayer:
				(child as CanvasLayer).visible = false
		await get_tree().process_frame
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var out_path := "res://.godot/captures/%s.png" % String(entry[0])
		image.save_png(out_path)
		print("CAPTURE %s" % out_path)
		level.queue_free()
		await get_tree().process_frame
	get_tree().quit()
