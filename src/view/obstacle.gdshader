shader_type spatial;
render_mode unshaded, cull_disabled;
// Places obstacles on their tiles on the GPU (ADR 0009). Mesh vertices hold tile-local coordinates:
// VERTEX.x = u across the lane, VERTEX.y = v along the segment, VERTEX.z = height in lane widths;
// UV.x is a fixed face brightness (the vertex colour is overridden by instancing). INSTANCE_CUSTOM = (lane, absolute segment, colour index, alive).

uniform vec3 frame_pos[51];
uniform vec3 frame_right[51];
uniform vec3 frame_up[51];
uniform vec2 section[17];
uniform vec2 face_normal[16];
uniform float first_segment = 0.0;
uniform float lane_width = 0.3901806;
uniform vec3 palette[5];

void vertex() {
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
	COLOR = vec4(palette[clamp(int(INSTANCE_CUSTOM.z + 0.5), 0, 4)] * UV.x, 1.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
