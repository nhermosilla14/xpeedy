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
varying float v_lane;
varying float v_seg;

// Hazard zone in force (0 none, 1 blackout, 2 gravity well, 3 hue shift, 4 dark nebula, 5 plasma cloud) and the
// seconds since it started (ADR 0023). Global uniforms: cheap to change every frame.
global uniform float zone;
global uniform float zone_time;
// Segment of the finish line of a stage race (-1 when there is none): the tiles fade to black before it.
global uniform float finish_segment;
// 1 while Phase Shift is active: trails are dimmed with no red highlight (doc 08).
global uniform float phase_shift;

void vertex() {
	int k = int(VERTEX.x + 0.5);
	int s = int(VERTEX.y + 0.5);
	v_local = vec2(VERTEX.x - UV.x, VERTEX.y - UV.y);
	vec2 c = section[k];
	VERTEX = frame_pos[s] + frame_right[s] * c.x + frame_up[s] * c.y;

	int tile_lane = int(UV.x + 0.5);
	v_lane = float(tile_lane);
	int tile_offset = int(UV.y + 0.5);
	int tile_seg = int(first_segment) + tile_offset;
	v_seg = float(tile_seg);
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
		// Blackout draws no trails.
		float shown = zone > 0.5 && zone < 1.5 ? 0.0 : 1.0;
		v_trail_fade = clamp((25.0 - dist) / 10.0, 0.0, 1.0) * weight * shown * (phase_shift > 0.5 ? 0.5 : 1.0);
		v_trail_highlight = clamp(approach * sqrt(max(0.0, 1.5 - lane_d)), 0.0, 1.0) * weight * shown * (phase_shift > 0.5 ? 0.0 : 1.0);
	}
	v_spot = floor(raw.a * 255.0 / 20.0 + 0.5);
}

void fragment() {
	float lane_d = min(v_local.x, 1.0 - v_local.x);

	// Surface: wide soft bands along the track.
	float t = fract((v_band_base + v_local.y) / BAND_PERIOD);
	float band = smoothstep(0.2, 0.45, t) - smoothstep(0.7, 0.95, t);
	bool is_line = false;
	vec3 colour = mix(SURFACE_DARK, SURFACE_LIGHT, band);
	if (zone > 0.5 && zone < 1.5) {
		// Blackout: a dark negative of the track.
		colour = (vec3(1.0) - colour) * 0.25;
	} else if (zone > 2.5 && zone < 3.5) {
		// Hue Shift: every lane oscillates between two obstacle colours at its own rate.
		float h1 = fract(sin(v_lane * 12.9898) * 43758.5453);
		float h2 = fract(sin(v_lane * 78.233) * 24634.6345);
		float h3 = fract(sin(v_lane * 39.346) * 17345.1371);
		vec3 a = palette[int(h1 * 4.99)];
		vec3 b = palette[int(h2 * 4.99)];
		float rate = 0.6 + 0.4 * h3;
		colour = mix(a, b, 0.5 + 0.5 * sin(6.2831853 * rate * zone_time)) * (0.55 + 0.3 * band);
	} else if (zone > 3.5 && zone < 4.5) {
		// Dark Nebula: the brightness pulses 0.5 +- 0.3 about every 1.3 s.
		colour *= (0.5 + 0.3 * sin(6.2831853 * zone_time / 1.3)) * 1.4;
	}

	// Trails: dark tinted fill, the rails still show through.
	colour = mix(colour, v_trail_colour * TRAIL_DARKEN, v_trail_fade * TRAIL_FILL);

	// Rails along every lane boundary.
	float rail = (1.0 - smoothstep(RAIL_CORE, RAIL_FADE, lane_d)) * RAIL_STRENGTH;
	colour = mix(colour, RAIL_COLOUR, rail);

	// Trail edge lines in the full colour, and the red-orange highlight.
	float edge = (1.0 - smoothstep(TRAIL_EDGE * 0.5, TRAIL_EDGE, lane_d)) * v_trail_fade;
	colour = mix(colour, v_trail_colour, edge);
	colour = mix(colour, WARNING, v_trail_highlight * max(edge, 0.35));

	if (v_spot > 10.5) {
		// Finish line: orange stripes across all lanes, like the zone marks.
		colour = mod(v_lane, 2.0) < 0.5 ? vec3(1.0, 0.6, 0.1) : vec3(0.95, 0.35, 0.05);
		is_line = true;
	} else if (v_spot > 9.5) {
		// Plasma vortex: a pulsing blue tile.
		float pulse = 0.5 + 0.5 * sin(zone_time * 8.0 + v_lane);
		colour = mix(vec3(0.15, 0.2, 0.9), vec3(0.8, 0.9, 1.0), pulse * (1.0 - length(v_local - 0.5)));
	} else if (v_spot > 4.5) {
		// Zone mark: two colours that hint at the zone, alternating by lane.
		float z = v_spot - 4.0;
		vec3 m1 = z < 1.5 ? vec3(1.0, 0.7, 0.1) : (z < 2.5 ? vec3(1.0) : (z < 3.5 ? vec3(0.05, 0.4, 0.1) : (z < 4.5 ? vec3(0.5, 0.2, 0.8) : vec3(0.8, 0.75, 1.0))));
		vec3 m2 = z < 1.5 ? vec3(0.9, 0.1, 0.6) : (z < 2.5 ? vec3(0.85, 0.85, 0.95) : (z < 3.5 ? vec3(0.1, 0.55, 0.2) : (z < 4.5 ? vec3(0.2, 0.3, 0.9) : vec3(0.7, 0.7, 0.95))));
		colour = mod(v_lane, 2.0) < 0.5 ? m1 : m2;
	} else if (v_spot > 0.5) {
		vec3 spot_colour = v_spot < 1.5 ? SHIELD_SPOT : (v_spot < 2.5 ? QUAKE_SPOT : (v_spot < 3.5 ? DILATION_SPOT : FOLD_SPOT));
		vec2 p = v_local * SPOT_CELLS;
		p.x += 0.5 * mod(floor(p.y), 2.0);
		float dots = 1.0 - smoothstep(SPOT_RADIUS * 0.8, SPOT_RADIUS, length(fract(p) - 0.5));
		colour = mix(SPOT_BASE, spot_colour, dots);
	}
	if (finish_segment > 0.0 && !is_line) {
		// The last segments fade to black over 10 segments (doc 11).
		colour *= 1.0 - clamp((v_seg + v_local.y - (finish_segment - 15.0)) / 10.0, 0.0, 1.0);
	}
	ALBEDO = colour;
}
