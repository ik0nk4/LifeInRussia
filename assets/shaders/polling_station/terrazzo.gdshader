shader_type spatial;
// Metre-scaled terrazzo: 600 mm slabs, fine aggregate and a quieter worn aisle.
varying vec3 world_position;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	vec2 tile = p / 0.6;
	vec2 edge = min(fract(tile), 1.0 - fract(tile)) * 0.6;
	float aa = max(fwidth(p.x), fwidth(p.y));
	float joint = 1.0 - smoothstep(0.0015, 0.0015 + aa, min(edge.x, edge.y));
	float variation = hash(floor(tile));
	vec3 stone = mix(vec3(0.34, 0.32, 0.275), vec3(0.43, 0.405, 0.35), variation);
	vec2 grain_uv = p * 210.0;
	vec2 grain_id = floor(grain_uv);
	float grain = hash(grain_id);
	float chip = 1.0 - smoothstep(0.18, 0.45, length(fract(grain_uv) - 0.5));
	float detail = 1.0 - smoothstep(0.3, 1.4, aa * 210.0);
	stone += (grain > 0.69 ? vec3(0.18) : vec3(-0.09)) * chip * detail;
	float border = smoothstep(2.9, 2.91, abs(p.x));
	stone = mix(stone, stone * vec3(0.52, 0.60, 0.61), border);
	ALBEDO = mix(stone, vec3(0.18, 0.175, 0.16), joint);
	float wear = exp(-p.x * p.x * 0.7);
	ROUGHNESS = mix(0.48 + variation * 0.1 - wear * 0.1, 0.88, joint);
	SPECULAR = 0.38;
}
