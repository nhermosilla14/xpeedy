# 0001. Tunnel prototype

- Status: In progress
- Date: 2026-11-05
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0002, 0003, 0004

## Goal
A player can fly through the Xpeedy tunnel and steer around it, with the tunnel behaving as described
in reference docs 02 and 03. The same build runs on desktop and on the RG351P fast enough to confirm
the engine choice.

## Acceptance criteria
- The tunnel is a 16-lane, radius-1 tube shown as a sliding 50-segment window that is built ahead
  of the ship and dropped behind it (doc 02).
- The ship starts at segment 3.5 on lane 7 (lane position 7.5), starts at 300 ms per segment, and eases
  to a target speed (default 80 ms, Standard) over 1.0 s of game time (docs 03, 17).
- The centre line curves following doc 02: straight start of ~30 segments, control points 10–20
  segments apart, 50 % straight chance, turn limits 10° to 30° (flat) or 50° (tube), 6 attempts,
  no twisting.
- The track follows the random part sequence (in/flat/out, multiples of 120, first part in ≥ 200)
  and morphs between shapes over 30 segments.
- Steering follows doc 03: *p* changes by dt × steer × 0.75, lane position = (1 − *p*) × 8, wrapping in
  tube shapes. Leaving the edge on flat parts, or crossing the seam during a morph outside the
  allowed windows, ends the run with a crash, and the player can restart.
- Keyboard (arrows / A–D) and gamepad (left stick, D-pad) steer through the response curve.
- First-person camera as in doc 03: 0.1875 above the surface, looking 3 segments ahead, 96° vertical
  FOV, purple exponential fog, banking on flat parts, slight shake while morphing.
- With the same seed, the generated path and part sequence are identical between runs and platforms.
- Packaged as a PortMaster port, it runs on the RG351P at a steady ≥ 30 fps at 480×320
  (the ADR 0002 threshold). The measured result is recorded.
- It runs on desktop Linux at the display's refresh rate.

## Out of scope
- Obstacles, spots, shields, bonuses, zones, scoring, menus, audio, upgrades.
- Android build and tilt/touch input (next target).
- Edge bands, starfield and visual polish beyond fog and basic tile colouring.

## Open questions
- None currently.
