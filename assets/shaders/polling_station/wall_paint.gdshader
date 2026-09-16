shader_type spatial;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 p = world_position;
	float fine = sin(p.x * 371.0 + p.z * 313.0) * sin(p.y * 419.0);
	float fade = 1.0 - smoothstep(0.002, 0.016, length(fwidth(p)));
	float lower = 1.0 - smoothstep(1.17, 1.175, p.y);
	vec3 cream = vec3(0.64, 0.615, 0.55);
	vec3 paint = vec3(0.285, 0.355, 0.335);
	float dirt = exp(-max(p.y, 0.0) * 9.0) * (0.03 + 0.018 * sin(p.x * 13.0 + p.z * 15.0));
	ALBEDO = mix(cream, paint, lower) + fine * 0.007 * fade - dirt;
	ROUGHNESS = mix(0.91, 0.64, lower) + fine * 0.025 * fade;
	SPECULAR = 0.25;
}
