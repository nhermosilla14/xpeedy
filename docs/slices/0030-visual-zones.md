# 0030. Blackout, Dark Nebula and Hue Shift

- Status: Accepted
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0008
- ADRs: 0023
- Depends on: slice 0029

## Scope
The `zone` and `zone_time` global uniforms, the tunnel and obstacle shader branches, the fog density per zone.

## Layers touched
- View: `tunnel.gdshader`, `obstacle.gdshader`, `look.gdshaderinc`, `ShipCamera`, `main.gd`.

## End-to-end test
- Shaders compile (the test runner fails on shader errors); fog density per zone unit-tested.
- Captures of each zone on a real GPU for the user's review.

## Out of scope
- Gravity Well, Plasma Cloud.
