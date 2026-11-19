extends GPUParticles3D
## Frees a one-shot particle burst once it has finished playing.

func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.4, false).timeout
	queue_free()
