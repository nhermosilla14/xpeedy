# 0012. Tunnel look: violet surface, bands and rails

- Status: Proposed
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0004
- ADRs: 0015
- Depends on: slice 0011

## Scope
The tunnel stops being a checkerboard: a blue-violet surface with soft wide bands, thick soft rails on every
lane boundary (on tube, flat and outside shapes, following bends), and the dark maroon void. A debug option
saves a screenshot of any state so the look can be checked on screen.

## Layers touched
- Foundation: `src/view/look.gdshaderinc` (palette, widths), the `--screenshot=PATH[,SECONDS]` launch option
  and its capture in `main.gd`, a script that captures a set of named states on a real GPU.
- View: `tunnel.gdshader` computes tile-local coordinates and the surface, bands and rails per fragment;
  `TunnelView` mesh data stays as it is (corner indexes are already there).

## End-to-end test
- Headless: all existing tests pass; the shaders compile (the test runner fails on shader errors); the
  launch option parser handles `--screenshot`.
- On a real GPU (desktop, script `tools/look-shots.sh`): screenshots of a fixed seed in an inside part, a
  flat part and an outside part are produced; automatic pixel checks on them: the wall is blue-violet (blue >
  red > green) and not a checkerboard (low variation between neighbouring tiles), bright lavender rails
  cross the wall regions, and the vanishing point is darker than the walls.
- Review with the user: side-by-side screenshots of the tunnel in the same situation;
  the user confirms or lists differences.

## Out of scope
- Trails, spots, obstacles, fragments (next slices), the HUD.
