shader_type spatial;
varying vec3 local_position;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() {
	local_position = VERTEX;
}
void fragment() {
	vec3 p = local_position;
	float bend = noise(p.xz * vec2(6.0, 2.0)) * 2.0;
	float grain = noise(vec2(p.x * 290.0 + bend, p.z * 3.0)) * 2.0 - 1.0;
	float pores = pow(noise(vec2(p.x * 970.0 + bend * 4.0, p.z * 18.0)), 4.0);
	float detail = 1.0 - smoothstep(0.001, 0.009, length(fwidth(p)));
	ALBEDO = vec3(0.40, 0.275, 0.15) + grain * vec3(0.07, 0.047, 0.027) * detail - pores * 0.04 * detail;
	ROUGHNESS = 0.55 + grain * 0.045 * detail;
	SPECULAR = 0.28;
}
