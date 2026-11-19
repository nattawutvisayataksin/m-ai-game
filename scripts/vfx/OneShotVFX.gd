extends Node3D
## Attach to impact and explosion VFX scenes.

@export var lifetime: float = 1.5

func _ready() -> void:
	for child in find_children("*", "GPUParticles3D", true, false):
		(child as GPUParticles3D).restart()
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
