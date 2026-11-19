shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float sway_strength = 0.08;
uniform float sway_speed = 1.5;
uniform float height_limit = 2.0;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp(VERTEX.y, 0.0, height_limit);
	VERTEX.x += sin(TIME * sway_speed + world.x * 0.5 + world.z * 0.3) * sway_strength * h;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + world.z * 0.5) * sway_strength * 0.5 * h;
}

void fragment() {
	vec4 color = texture(albedo_tex, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
