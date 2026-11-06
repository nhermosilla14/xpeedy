shader_type spatial;
render_mode unshaded, cull_disabled;
// Places the tunnel's vertices on the GPU (ADR 0007). Each mesh vertex carries its lane vertex index
// in VERTEX.x (0-16) and its segment offset within the window in VERTEX.y (0-50); COLOR.r is the
// tile's checker parity relative to the first visible segment.

uniform vec3 frame_pos[51];
uniform vec3 frame_right[51];
uniform vec3 frame_up[51];
uniform vec2 section[17];
uniform float first_parity = 0.0;

const vec3 TILE_LIGHT = vec3(1.0, 1.0, 1.0);
const vec3 TILE_DARK = vec3(0.82, 0.82, 0.86);

void vertex() {
	int k = int(VERTEX.x + 0.5);
	int s = int(VERTEX.y + 0.5);
	vec2 c = section[k];
	VERTEX = frame_pos[s] + frame_right[s] * c.x + frame_up[s] * c.y;
	COLOR = vec4(abs(COLOR.r - first_parity), 0.0, 0.0, 1.0);
}

void fragment() {
	ALBEDO = mix(TILE_LIGHT, TILE_DARK, COLOR.r);
}
