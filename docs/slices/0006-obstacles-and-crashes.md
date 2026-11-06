# 0006. Obstacles and crashes

- Status: Proposed
- Date: 2026-11-06
- Owner: agent
- Intents: 0003
- ADRs: 0008, 0009
- Depends on: slice 0005

## Scope
Obstacles appear in the tunnel and ending a run on touching one. Only the level-0 pattern (a single
cube or a single beam, 50/50) exists, placed from segment 55 with Survival spacing. They are drawn by
the GPU, can be dodged or hit (including seam wrap and tube beams reaching the opposite lane), and a
hit is a crash that uses the existing crash camera and restart.

## Layers touched
- Foundation: `RunConfig` (Standard), `TrackShaderBinding` (shared uniform upload for tunnel and
  obstacle materials), run events plumbing.
- Model: `SurvivalRun`, `ObstacleField` (storage per segment, horizon-driven generation with its own
  PRNG stream), a minimal `PatternLibrary` (level 0 only), swept collision with seam wrap and the beam
  rules.
- View: `ObstacleView` (three `MultiMeshInstance3D`s, `obstacle.gdshader`, instance buffer rewrite on
  change), `main.gd` driving `SurvivalRun`.

## End-to-end test
- Unit tests: placement points follow doc 10 (first at 55, spacing 12 then shrinking); same seed gives
  the same obstacles regardless of request order; hit box edges (segment −0.6 and +1, lane ±0.25);
  seam wrap on lanes 0 and 15 in tubes and none on flat or while morphing; a tube beam hits its
  opposite lane (and only while the tunnel is ≥ 80 % tube-shaped); a sweep over a long tick cannot skip
  an obstacle; an obstacle crash sets `crashed` and `crash_reason`.
- Scene test through the real input map: steering into the first obstacle crashes, then restart; a
  second run steers around it and survives past it. The instance buffer and uniforms match the model.
- Desktop visual check: cubes and beams (tube and pole) sit on their tiles through a morph.

## Out of scope
- Trails, spikes, other patterns, shields, spots, score, HUD, effects.
