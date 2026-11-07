shader_type spatial;
render_mode unshaded, cull_disabled;
// Places the tunnel's vertices on the GPU (ADR 0007) and draws its look procedurally (ADR 0015).
// Mesh vertices carry VERTEX.x = lane vertex index (0-16) and VERTEX.y = segment offset in the window
// (0-50); UV = (lane, segment offset) of the tile. The vertex stage works out what is constant over a
// tile (its trail, its spot, its band position) and the tile-local coordinates; the fragment stage
// paints the surface, the rails and the trail from them.
// The trail formulas repeat TrailMath (src/model/trail_math.gd), which the unit tests check.

#include "res://src/view/look.gdshaderinc"

uniform vec3 frame_pos[51];
uniform vec3 frame_right[51];
uniform vec3 frame_up[51];
uniform vec2 section[17];
uniform float first_segment = 0.0;
uniform float first_parity = 0.0;
uniform vec3 palette[5];
// 16 x 64 RGBA8 (ADR 0011): R colour index + 1 (0 = no trail), G obstacle segment minus the tile's
// segment, B opposite-lane flag, A spot flag. The handhelds can't sample float textures.
uniform sampler2D trail_tex : filter_nearest;
uniform float ship_segment = 0.0;
uniform float ship_lane = 7.5;
uniform float wrap_seam = 1.0;
uniform float tube_weight = 1.0;

varying vec2 v_local;          // position inside the tile, 0-1 across the lane and along the segment
varying float v_band_base;     // the tile's segment modulo the band period
varying vec3 v_trail_colour;
varying float v_trail_fade;    // how much of the trail colour shows (0 = no trail)
varying float v_trail_highlight;
varying float v_spot;

void vertex() {
	int k = int(VERTEX.x + 0.5);
	int s = int(VERTEX.y + 0.5);
	v_local = vec2(VERTEX.x - UV.x, VERTEX.y - UV.y);
	vec2 c = section[k];
	VERTEX = frame_pos[s] + frame_right[s] * c.x + frame_up[s] * c.y;

	int tile_lane = int(UV.x + 0.5);
	int tile_offset = int(UV.y + 0.5);
	int tile_seg = int(first_segment) + tile_offset;
	v_band_base = mod(float(tile_seg), BAND_PERIOD);

	v_trail_colour = vec3(0.0);
	v_trail_fade = 0.0;
	v_trail_highlight = 0.0;
	vec4 raw = texelFetch(trail_tex, ivec2(tile_lane, tile_seg & 63), 0);
	float code = floor(raw.r * 255.0 + 0.5);
	if (code > 0.5) {
		float obstacle_seg = float(tile_seg) + floor(raw.g * 255.0 + 0.5);
		float dist = obstacle_seg - ship_segment;
		float weight = raw.b > 0.5 ? tube_weight : 1.0;
		float lane_d = abs(ship_lane - (float(tile_lane) + 0.5));
		lane_d = mix(lane_d, min(lane_d, 16.0 - lane_d), wrap_seam);
		float approach = clamp((15.0 - dist) / 10.0, 0.0, 1.0);
		v_trail_colour = palette[int(code - 0.5)];
		v_trail_fade = clamp((25.0 - dist) / 10.0, 0.0, 1.0) * weight;
		v_trail_highlight = clamp(approach * sqrt(max(0.0, 1.5 - lane_d)), 0.0, 1.0) * weight;
	}
	v_spot = raw.a > 0.5 ? 1.0 : 0.0;
}

void fragment() {
	float lane_d = min(v_local.x, 1.0 - v_local.x);

	// Surface: wide soft bands along the track.
	float t = fract((v_band_base + v_local.y) / BAND_PERIOD);
	float band = smoothstep(0.2, 0.45, t) - smoothstep(0.7, 0.95, t);
	vec3 colour = mix(SURFACE_DARK, SURFACE_LIGHT, band);

	// Rails along every lane boundary.
	float rail = (1.0 - smoothstep(RAIL_CORE, RAIL_FADE, lane_d)) * RAIL_STRENGTH;
	colour = mix(colour, RAIL_COLOUR, rail);

	// Trails and spots keep their previous look until their own restyle.
	colour = mix(colour, v_trail_colour, v_trail_fade);
	colour = mix(colour, WARNING, v_trail_highlight);
	if (v_spot > 0.5) {
		colour = SHIELD_SPOT;
	}
	ALBEDO = colour;
}
