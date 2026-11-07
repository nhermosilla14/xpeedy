shader_type spatial;
render_mode unshaded, cull_disabled;
// Explosion fragments, moved entirely on the GPU (ADR 0012). Each instance sits at the explosion origin
// (its transform's translation); INSTANCE_CUSTOM = (spawn time, colour index, seed, active). Direction,
// speed and spin come from the seed. Fragments fly out ballistically, tumble, shrink and vanish.

#include "res://src/view/look.gdshaderinc"

uniform float game_time = 0.0;
uniform vec3 palette[5];

const float LIFE = 0.8;
const float SIZE = 0.1;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

mat3 rotation(vec3 axis, float angle) {
	vec3 a = normalize(axis);
	float c = cos(angle);
	float s = sin(angle);
	float t = 1.0 - c;
	return mat3(
		vec3(t * a.x * a.x + c, t * a.x * a.y + s * a.z, t * a.x * a.z - s * a.y),
		vec3(t * a.x * a.y - s * a.z, t * a.y * a.y + c, t * a.y * a.z + s * a.x),
		vec3(t * a.x * a.z + s * a.y, t * a.y * a.z - s * a.x, t * a.z * a.z + c));
}

varying vec2 v_quad;

void vertex() {
	v_quad = VERTEX.xy + 0.5;
	float age = game_time - INSTANCE_CUSTOM.x;
	float seed = INSTANCE_CUSTOM.z;
	bool shown = INSTANCE_CUSTOM.w > 0.5 && age >= 0.0 && age < LIFE;
	vec3 dir = normalize(vec3(hash(seed) - 0.5, hash(seed + 1.7) - 0.5, hash(seed + 3.1) - 0.5) + vec3(0.001));
	float speed = 1.0 + 3.0 * hash(seed + 5.3);
	vec3 axis = vec3(hash(seed + 7.1) - 0.5, hash(seed + 9.7) - 0.5, hash(seed + 11.3) - 0.5) + vec3(0.001);
	float spin = (hash(seed + 13.9) - 0.5) * 20.0;
	float size = SIZE * (1.0 - age / LIFE);
	vec3 moved = rotation(axis, spin * age) * (VERTEX * size) + dir * speed * age;
	VERTEX = shown ? moved : vec3(0.0);
	COLOR = vec4(palette[clamp(int(INSTANCE_CUSTOM.y + 0.5), 0, 4)], 1.0);
}

void fragment() {
	float edge = 1.0 - smoothstep(0.1, 0.2, min(min(v_quad.x, 1.0 - v_quad.x), min(v_quad.y, 1.0 - v_quad.y)));
	ALBEDO = mix(COLOR.rgb * BODY_BRIGHTNESS * 1.5, COLOR.rgb, edge);
}
