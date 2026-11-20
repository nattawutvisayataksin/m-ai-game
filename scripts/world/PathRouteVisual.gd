class_name PathRouteVisual
extends MeshInstance3D
## Makes the enemy route visible during gameplay.

@export var route_color: Color = Color(0.95, 0.72, 0.24, 0.95)
@export var route_width: float = 0.16
@export var sample_step: float = 0.35

func _ready() -> void:
	var path := get_parent() as Path3D
	if path == null or path.curve == null:
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = route_color
	material.emission_enabled = true
	material.emission = route_color
	material.emission_energy_multiplier = 1.8
	var immediate := ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	var length := path.curve.get_baked_length()
	var distance := 0.0
	while distance <= length:
		var point := path.curve.sample_baked(distance)
		point.y += 0.08
		immediate.surface_add_vertex(point)
		distance += sample_step
	immediate.surface_end()
	mesh = immediate
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
