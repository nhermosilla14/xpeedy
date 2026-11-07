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

// Rollers and bouncers move with the run's game time (ADR 0020, 0021). The formulas repeat MovingMath
// (src/model/moving_math.gd). INSTANCE_CUSTOM.z = colour + 8 * shape + 24 * (turns towards +lane) + 48 for a
// roller or 96 for a bouncer; INSTANCE_CUSTOM.w = 1 + phase for shown obstacles, 0 for hidden ones.
uniform float game_time = 0.0;
uniform float target_tps = 80.0;

float lane_after(float from_lane, float dir, float steps, bool is_flat) {
	if (is_flat) {
		float x = mod(from_lane + dir * steps + 3000.0, 30.0);
		return x <= 15.0 ? x : 30.0 - x;
	}
	return mod(from_lane + dir * steps + 1600.0, 16.0);
}

void vertex() {
	v_tile = VERTEX;
	float code = INSTANCE_CUSTOM.z;
	float kind = floor(code / 48.0);
	float rest = code - kind * 48.0;
	float toward_plus = floor(rest / 24.0);
	rest -= toward_plus * 24.0;
	float shape_code = floor(rest / 8.0);
	float colour = rest - shape_code * 8.0;
	float phase = INSTANCE_CUSTOM.w - 1.0;

	float rel = INSTANCE_CUSTOM.y - first_segment;
	bool shown = INSTANCE_CUSTOM.w > 0.5 && rel > -0.5 && rel < 49.5;
	float lane_f = INSTANCE_CUSTOM.x;
	float u = VERTEX.x;
	float h = VERTEX.z;
	if (kind > 0.5 && kind < 1.5) {
		bool is_flat = shape_code > 0.5 && shape_code < 1.5;
		float angle_deg = shape_code < 0.5 ? 60.0 : (is_flat ? 90.0 : 120.0);
		float step_time = angle_deg / (290.0 - target_tps);
		float cycle = step_time + 0.2;
		float shifted = max(game_time + phase, 0.0);
		float n = floor(shifted / cycle);
		float within = shifted - n * cycle;
		bool moving = within < step_time;
		float k = moving ? n : n + 1.0;
		float dir = toward_plus > 0.5 ? 1.0 : -1.0;
		float here = lane_after(lane_f, dir, k, is_flat);
		float there = lane_after(lane_f, dir, k + 1.0, is_flat);
		lane_f = here;
		if (moving) {
			float step_dir = is_flat ? sign(there - here) : dir;
			float a = within / step_time * 1.5707963;
			float um = step_dir > 0.0 ? u : 1.0 - u;
			float du = um - 1.0;
			float nu = 1.0 + du * cos(a) + h * sin(a);
			float nh = -du * sin(a) + h * cos(a);
			u = step_dir > 0.0 ? nu : 1.0 - nu;
			h = nh;
			if (u > 1.0) {
				u -= 1.0;
				lane_f = there;
			} else if (u < 0.0) {
				u += 1.0;
				lane_f = there;
			}
		}
	} else if (kind > 1.5) {
		float range = shape_code < 0.5 ? 1.96 : 1.57;
		float half_period = (1000.0 - 4.0 * (target_tps - 100.0)) / 1000.0;
		h += range * 0.5 * (1.0 - cos(3.14159265 * (game_time + phase) / half_period)) / lane_width;
	}

	int lane = clamp(int(lane_f + 0.5), 0, 15);
	int s = clamp(int(rel + 0.5), 0, 49);
	vec2 pt = mix(section[lane], section[lane + 1], u);
	vec2 nrm = face_normal[lane];
	vec3 near_point = frame_pos[s] + frame_right[s] * pt.x + frame_up[s] * pt.y;
	vec3 far_point = frame_pos[s + 1] + frame_right[s + 1] * pt.x + frame_up[s + 1] * pt.y;
	vec3 near_normal = frame_right[s] * nrm.x + frame_up[s] * nrm.y;
	vec3 far_normal = frame_right[s + 1] * nrm.x + frame_up[s + 1] * nrm.y;
	vec3 base = mix(near_point, far_point, VERTEX.y);
	vec3 up_dir = normalize(mix(near_normal, far_normal, VERTEX.y));
	// Hidden obstacles collapse to a point and draw nothing.
	VERTEX = shown ? base + up_dir * h * lane_width : vec3(0.0);
	v_edge_colour = palette[clamp(int(colour + 0.5), 0, 4)];
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
