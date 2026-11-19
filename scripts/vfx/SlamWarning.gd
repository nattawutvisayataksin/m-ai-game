class_name SlamWarning
extends Node3D
## Expanding ground ring that warns where a boss slam will land.

@export var duration: float = 0.9
@export var radius: float = 4.5

@onready var ring: MeshInstance3D = $Ring
@onready var fill: MeshInstance3D = $Fill

func _ready() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - 0.16, 0.1)
	torus.outer_radius = radius
	torus.rings = 48
	torus.ring_segments = 4
	ring.mesh = torus
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.02
	fill.mesh = disc
	scale = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fill, "scale", Vector3.ONE, duration)
	await get_tree().create_timer(duration, false).timeout
	queue_free()
