# 0008. Shield spots, shields and the HUD

- Status: Proposed
- Date: 2026-11-06
- Owner: agent
- Intents: 0003
- ADRs: 0008, 0009, 0010
- Depends on: slice 0007

## Scope
Orange shield spots appear on the track and are collected by flying over them. Shields stack up to 4,
decay on a single 20 s timer, and are shown on the screen next to the score. Distance already scores
points. Collecting a spot gives the orange flash. Shields are not yet spent on obstacles.

## Layers touched
- Model: `SpotField` (doc 10 placement with its own PRNG stream, collection test with seam wrap),
  `ShieldStack` (max, decay timer, restart on pick-up even when full), distance score, `RunEvent`s for
  pick-ups.
- View: spots painted through the `TrailMap` texel's A channel and the tunnel shader (orange tile),
  `Hud` (score label, shield slots with decay fill), `ScreenFlash`.

## End-to-end test
- Unit tests: spot placement points and group sizes follow doc 10 (first at 100, 1-in-8 skips, size
  growth, even ring spread); the same seed gives the same spots; collecting once per spot; footprint is
  1 lane × 3 segments; shield stack caps at 4, decays one unit every 20 s, the timer restarts on
  pick-up even when full, nothing goes negative; distance score is +1 per segment and restarts at 0
  with a new run.
- Scene test: steering onto a spot raises the shield count and the HUD value, the HUD score grows with
  distance, the stack decays over game time.
- Desktop visual check: spots are visible orange tiles, the HUD is readable at 480×320.

## Out of scope
- Spending shields on obstacles, smash points (slice 0009), bonus spots.
