shader_type spatial;
render_mode unshaded, cull_disabled;
// Places obstacles on their tiles on the GPU (ADR 0009). Mesh vertices hold tile-local coordinates:
// VERTEX.x = u across the lane, VERTEX.y = v along the segment, VERTEX.z = height in lane widths;
// UV.x is a fixed face brightness, UV.y = 1 for the spike mesh. UV2 = (inset, height) for boxes and two
// barycentric coordinates for spikes, for the edge lines (ADR 0015). The vertex colour is overridden by instancing. INSTANCE_CUSTOM = (lane, absolute segment, colour index, alive).

#include "res://src/view/look.gdshaderinc"

uniform vec3 frame_pos[51];
uniform vec3 frame_right[51];
uniform vec3 frame_up[51];
uniform vec2 section[17];
uniform vec2 face_normal[16];
uniform float first_segment = 0.0;
uniform float lane_width = 0.3901806;
uniform vec3 palette[5];

varying vec3 v_tile;
varying vec3 v_edge_colour;
varying float v_shade;

void vertex() {
	v_tile = VERTEX;
	float rel = INSTANCE_CUSTOM.y - first_segment;
	bool shown = INSTANCE_CUSTOM.w > 0.5 && rel > -0.5 && rel < 49.5;
	int lane = clamp(int(INSTANCE_CUSTOM.x + 0.5), 0, 15);
	int s = clamp(int(rel + 0.5), 0, 49);
	vec2 pt = mix(section[lane], section[lane + 1], VERTEX.x);
	vec2 nrm = face_normal[lane];
	vec3 near_point = frame_pos[s] + frame_right[s] * pt.x + frame_up[s] * pt.y;
	vec3 far_point = frame_pos[s + 1] + frame_right[s + 1] * pt.x + frame_up[s + 1] * pt.y;
	vec3 near_normal = frame_right[s] * nrm.x + frame_up[s] * nrm.y;
	vec3 far_normal = frame_right[s + 1] * nrm.x + frame_up[s + 1] * nrm.y;
	vec3 base = mix(near_point, far_point, VERTEX.y);
	vec3 up_dir = normalize(mix(near_normal, far_normal, VERTEX.y));
	// Hidden obstacles collapse to a point and draw nothing.
	VERTEX = shown ? base + up_dir * VERTEX.z * lane_width : vec3(0.0);
	v_edge_colour = palette[clamp(int(INSTANCE_CUSTOM.z + 0.5), 0, 4)];
	v_shade = UV.x;
	COLOR = vec4(UV.y, UV2.x, UV2.y, 1.0);
}

void fragment() {
	float edge;
	if (COLOR.r > 0.5) {
		vec3 b = vec3(COLOR.g, COLOR.b, 1.0 - COLOR.g - COLOR.b);
		edge = 1.0 - smoothstep(SPIKE_EDGE * 0.5, SPIKE_EDGE, min(b.x, min(b.y, b.z)));
	} else {
		float inset = UV2.x;
		float height = UV2.y;
		vec3 d = vec3(min(v_tile.x - inset, 1.0 - inset - v_tile.x),
			min(v_tile.y - inset, 1.0 - inset - v_tile.y),
			min(v_tile.z, height - v_tile.z));
		vec3 near = vec3(1.0) - smoothstep(vec3(OBSTACLE_EDGE * 0.5), vec3(OBSTACLE_EDGE), d);
		edge = max(near.x * near.y, max(near.y * near.z, near.x * near.z));
	}
	ALBEDO = mix(v_edge_colour * BODY_BRIGHTNESS * (0.6 + 0.4 * v_shade), v_edge_colour, edge);
}
