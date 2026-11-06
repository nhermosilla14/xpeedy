shader_type spatial;
render_mode unshaded, cull_disabled;
// Places the tunnel's vertices on the GPU (ADR 0007) and colours its tiles, including the warning
// trails (ADR 0009). Mesh vertices carry VERTEX.x = lane vertex index (0-16) and VERTEX.y = segment
// offset in the window (0-50); UV = (lane, segment offset) of the tile; COLOR.r = checker parity
// relative to the first visible segment.
// The trail formulas repeat TrailMath (src/model/trail_math.gd), which the unit tests check.

uniform vec3 frame_pos[51];
uniform vec3 frame_right[51];
uniform vec3 frame_up[51];
uniform vec2 section[17];
uniform float first_segment = 0.0;
uniform float first_parity = 0.0;
uniform vec3 palette[5];
// 16 x 64 RGBAF: R colour index or -1, G obstacle segment, B opposite-lane flag, A spot flag.
uniform sampler2D trail_tex : filter_nearest;
uniform float ship_segment = 0.0;
uniform float ship_lane = 7.5;
uniform float wrap_seam = 1.0;
uniform float tube_weight = 1.0;

const vec3 TILE_LIGHT = vec3(1.0, 1.0, 1.0);
const vec3 TILE_DARK = vec3(0.82, 0.82, 0.86);
const vec3 WARNING = vec3(0.94, 0.12, 0.05);

void vertex() {
	int k = int(VERTEX.x + 0.5);
	int s = int(VERTEX.y + 0.5);
	vec2 c = section[k];
	VERTEX = frame_pos[s] + frame_right[s] * c.x + frame_up[s] * c.y;

	float parity = abs(COLOR.r - first_parity);
	vec3 colour = mix(TILE_LIGHT, TILE_DARK, parity);
	int tile_lane = int(UV.x + 0.5);
	int tile_seg = int(first_segment) + int(UV.y + 0.5);
	vec4 trail = texelFetch(trail_tex, ivec2(tile_lane, tile_seg & 63), 0);
	if (trail.r > -0.5) {
		float dist = trail.g - ship_segment;
		float weight = trail.b > 0.5 ? tube_weight : 1.0;
		float fade = clamp((25.0 - dist) / 10.0, 0.0, 1.0);
		float lane_d = abs(ship_lane - (float(tile_lane) + 0.5));
		lane_d = mix(lane_d, min(lane_d, 16.0 - lane_d), wrap_seam);
		float approach = clamp((15.0 - dist) / 10.0, 0.0, 1.0);
		float hl = clamp(approach * sqrt(max(0.0, 1.5 - lane_d)), 0.0, 1.0);
		colour = mix(colour, palette[int(trail.r + 0.5)], fade * weight);
		colour = mix(colour, WARNING, hl * weight);
	}
	COLOR = vec4(colour, 1.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
