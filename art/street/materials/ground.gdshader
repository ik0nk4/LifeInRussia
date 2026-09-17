shader_type spatial;
render_mode specular_disabled;

uniform vec4 base_color : source_color = vec4(0.6, 0.59, 0.53, 1.0);
uniform float tile_strength = 0.12;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_position.xz / vec2(0.6, 0.4);
	uv.x += mod(floor(uv.y), 2.0) * 0.5;
	vec2 edge = min(fract(uv), 1.0 - fract(uv));
	vec2 aa = max(fwidth(uv), vec2(0.001));
	vec2 seam = 1.0 - smoothstep(vec2(0.008), vec2(0.008) + aa, edge);
	float joints = max(seam.x, seam.y);
	// Low amplitude broad variation stays stable at a distance.
	float variation = sin(world_position.x * 1.9 + sin(world_position.z * 2.4)) * 0.015;
	ALBEDO = base_color.rgb * (1.0 - joints * tile_strength + variation);
	ROUGHNESS = 0.95;
}
