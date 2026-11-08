// Shared look constants (ADR 0015). Colours are linear values as the shaders use them; the comments give
// the approximate screen colour they should produce.

// Surface: blue-violet with soft wide bands along the track.
const vec3 SURFACE_LIGHT = vec3(0.34, 0.31, 0.64);   // about #5A52A8
const vec3 SURFACE_DARK = vec3(0.27, 0.25, 0.55);    // about #4A4694
const float BAND_PERIOD = 6.0;                       // segments from one light band to the next

// Rails: a soft bright strip centred on every lane boundary. Distances are in lane widths.
const vec3 RAIL_COLOUR = vec3(0.79, 0.76, 0.82);     // about #C9C3D1
const float RAIL_CORE = 0.07;                        // solid half-width
const float RAIL_FADE = 0.2;                         // half-width where it has faded out
const float RAIL_STRENGTH = 0.9;

// Trails: darkened fill over the surface, bright lines on the lane borders (lane widths).
const float TRAIL_DARKEN = 0.3;
const float TRAIL_FILL = 0.85;
const float TRAIL_EDGE = 0.07;

// Shield spots: a hex mesh of amber dots on near-black.
const vec3 SPOT_BASE = vec3(0.02, 0.01, 0.01);
const vec3 QUAKE_SPOT = vec3(0.64, 0.02, 0.26);
const vec3 DILATION_SPOT = vec3(0.30, 0.50, 1.0);
const vec3 FOLD_SPOT = vec3(0.47, 0.69, 0.0);
const float SPOT_CELLS = 6.0;
const float SPOT_RADIUS = 0.34;

const vec3 WARNING = vec3(0.94, 0.12, 0.05);
const vec3 SHIELD_SPOT = vec3(1.0, 0.7, 0.2);

// Obstacles: a dark body (fraction of the colour) with bright edge lines (lane widths wide).
const float BODY_BRIGHTNESS = 0.16;
const float OBSTACLE_EDGE = 0.07;
const float SPIKE_EDGE = 0.06;
