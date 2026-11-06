# 0008. Shield spots, shields and the HUD

- Status: Done
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

## Results (2026-11-06)
- 110 unit tests and 5 end-to-end tests pass. New unit tests cover: the shield stack (cap of 4, one unit
  per 20 s, long ticks, restart on pick-up even when full, restart on loss, idle at zero); spot
  placement against doc 10 (first group at 100, gaps of at least 3 × the obstacle spacing and the whole
  36–47 range early on, size 1 before segment 450 and up to 2 and 3 later, even ring spread, same seed
  and request-order independence); collection (three segments long, ±0.25 lanes, seam wrap, once only,
  events, timer restart when full); distance score; and the spot flag in the trail map.
- `tests/e2e_shields_spots.gd`, through the real scene: the first spot is painted in the map and in the
  uploaded texture, steering onto it gives one shield, the HUD shows the right score, slots and decay
  level, the pick-up flash appears, the spot's paint is gone and the texture is up to date.
- Desktop visual check at 480×320 with `opengl3_es` (real GPU): orange spot tiles on the track, score
  bottom left, four shield slots bottom right with the fill level dropping as the timer runs, and the
  count rising on pick-up.
- Desktop frame rate with obstacles, trails and spots: 103–115 fps average, 54–79 fps 1 % low. CPU per
  tick: views 0.10–0.12 ms.

## Change after review (2026-11-06)
- The user pointed out that the HUD drew four separate slots, each draining at the same time, so it read
  as four shields with four timers (the model has one timer for the whole stack). A sketch showed the
  wanted look: one frame with four compartments and one fill that shrinks from the right, one
  compartment per 20 s (half a compartment after 10 s).
- Recorded as ADR 0012 (replacing 0010). `ShieldStack.level()` gives the bar's charge in segments and
  falls steadily, also across an expiry; `Hud` draws the common bar from it. The pick-up and spend rules
  of doc 05 are unchanged. Tests added for the level over time and across an expiry; the scene test now
  checks the HUD's bar level against the model.
- Desktop visual check at 480×320 with `-- --ghost --shields=4`: about 9 s in the last compartment is
  part drained from its right end, at about 19 s three compartments are full and the last is empty.
- Added the `--shields=N` debug launch option (starts the run with N shields).
