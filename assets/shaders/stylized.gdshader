shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D emission_tex : source_color, hint_default_black;
uniform float emission_strength : hint_range(0.0, 8.0) = 2.0;
uniform float ramp_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float ramp_smooth : hint_range(0.001, 0.5) = 0.05;
uniform vec4 shadow_tint : source_color = vec4(0.55, 0.62, 0.78, 1.0);
uniform vec4 light_tint : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_amount : hint_range(0.0, 2.0) = 0.35;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform sampler2D noise_tex : hint_default_white;
uniform vec4 dissolve_edge_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
instance uniform float hit_flash = 0.0;
instance uniform float dissolve_amount = 0.0;

void fragment() {
	float n = texture(noise_tex, UV * 2.0).r;
	if (dissolve_amount > 0.0 && n < dissolve_amount) {
		discard;
	}
	vec3 base = texture(albedo_tex, UV).rgb * tint.rgb;
	ALBEDO = mix(base, flash_color.rgb, hit_flash);
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	vec3 emit = texture(emission_tex, UV).rgb * emission_strength;
	emit += flash_color.rgb * hit_flash * 0.8;
	float edge = step(n, dissolve_amount + 0.06) * step(0.001, dissolve_amount);
	emit += dissolve_edge_color.rgb * edge * 4.0;
	EMISSION = emit;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float lit = smoothstep(ramp_threshold - ramp_smooth, ramp_threshold + ramp_smooth, ndl);
	lit *= smoothstep(0.3, 0.6, ATTENUATION);
	vec3 ramp_color = mix(shadow_tint.rgb, light_tint.rgb, step(0.5, lit));
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * ramp_color * lit;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	SPECULAR_LIGHT += rim * rim_amount * rim_color.rgb * LIGHT_COLOR / PI * lit;
}
