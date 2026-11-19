class_name CoinPop
extends Node3D

@export var lifetime: float = 0.7
@export var height: float = 1.2

func _ready() -> void:
	var start: Vector3 = position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start.y + height, lifetime)
	tween.tween_property(self, "scale", Vector3.ONE * 1.25, lifetime * 0.25)
	tween.set_parallel(false)
	tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.5)
	tween.tween_callback(queue_free)
