# 0008. Survival run model: obstacles, spots, shields and score

- Status: Accepted
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
Intent 0003 adds obstacles, shield spots, shields, scoring and crashes on top of `TrackModel`. The rules
come from reference docs 04, 05, 06, 09 and 10. Several details need an explicit reading, and the
gameplay must stay deterministic, testable without rendering and independent of draw order
(ADR 0005).

## Decision

### Structure
- `SurvivalRun` (plain `RefCounted`, `src/model/`) owns a `TrackModel`, a `RunConfig`, an
  `ObstacleField`, a `SpotField`, a `ShieldStack` and the score. `main.gd` keeps `_track` (the
  `TrackModel`) and gains `_run`.
- `RunConfig` holds everything a difficulty changes: target TPS, obstacle kinds enabled, max shields,
  decay seconds. `RunConfig.standard()` is the only preset for now (80 ms, cubes/beams/spikes, 4
  shields, 20 s). Other difficulties are later presets, not new code paths.
- `SurvivalRun.step(dt, steer)` runs, in order: `TrackModel.step`; if not crashed: generate obstacles
  and spots up to the horizon (`window_start + 50`), resolve obstacle collisions over the swept
  distance, resolve spot pick-ups, advance the shield decay timer, add distance score. It appends
  `RunEvent`s (smash, pick-up, crash, with obstacle/spot, colour and points) that views consume with
  `take_events()`; events never feed back into the model.
- An obstacle crash sets `TrackModel.crashed` (with `crash_reason`), so the existing crash camera,
  freeze and restart work unchanged.

### World coordinates
- An obstacle is `(segment: int, lane: int 0–15, kind, colour 0–4)`. It occupies the tile
  lanes [lane, lane+1) × segments [segment, segment+1). The part shape at its segment when generated is
  stored, because it decides whether a beam is a tube beam (IN) or a pole (FLAT/OUT).
- Obstacles are stored per segment (`Dictionary` segment → array) and dropped once behind the ship.

### Generation
- Patterns are placed at points p₀ = 55, pₖ₊₁ = pₖ + max(8, 12 − ⌊pₖ/300⌋), with d = pₖ and
  level = ⌊pₖ/150⌋, as doc 10 says. Placement is driven only by the horizon advancing, never by a
  request from a view, so request order cannot change the track.
- Own PRNG stream `seed ^ 0x0B57AC1E` for obstacles and `seed ^ 0x5B07` for spots (ADR 0005). The draw
  order of each pattern is documented in `PatternLibrary` and `docs/architecture.md`.
- Interpretations of doc 04 where it is silent:
  - "before the next shape change" means the whole pattern lies inside the part containing its
    placement point;
  - a pattern picks **one colour** for all its obstacles, except variants described as mixed or
    two-colour;
  - contiguous formations (walls, diagonals) on FLAT parts choose their start so they fit in lanes
    0–15 without wrapping; on tube parts they wrap modulo 16; "evenly spread" and "n apart" patterns
    use modulo 16 everywhere;
  - doc 10's "random(0 … x)" ranges are inclusive integers.
- Spot groups: first at segment 100, next at pₛ + 3·s + random(0 … s−1) with s the current obstacle
  spacing, a 1-in-8 chance of skipping, size 1 + random(0 … ⌊d/450⌋) capped at 3, spread every
  ⌊i·16/n⌋ lanes from a random start. With bonuses not yet implemented, every spot is a shield spot. A
  spot occupies lane × segments [seg, seg+3).

### Collisions
- The ship's segment span in a tick is swept from `a` (before) to `b` (after); its lane position is
  swept the same way between `l0` and `l1`. An obstacle at segment `s` is hit when `a ≤ s + 1` and
  `b ≥ s − 0.6`, and the lane range [min(l0,l1) − 0.25, max(l0,l1) + 0.25] overlaps
  [lane, lane + 1). Spots use the same test with `s + 3` as upper bound.
- Seam wrap: the obstacle's lane range is also tested shifted by ±16 when the track is a tube part and
  not morphing.
- A tube beam (stored shape IN) also occupies lane (lane + 8) mod 16, while the tunnel is at least 80 %
  tube-shaped (`flatness ≤ 0.2`). Obstacles after the morph boundary belong to the new part, so the
  doc's "leaving in" case never arises with ADR 0006's morph timing.
- Obstacles in the swept range are resolved in segment order: a cube or spike needs 1 shield, a beam
  2; otherwise crash. Several smashes in one tick are allowed.

### Shields and score
- `ShieldStack`: count 0…max, one decay timer in game time. Expiry removes one unit (if any) and
  restarts the timer; pick-up (even when full), collision loss and recharger restart it.
- Score: +1 per whole segment travelled since the start, plus smash points (cube/spike 100, beam 300),
  never below 0.

## Alternatives considered
- Putting gameplay into `TrackModel` — it would mix path/shape state with rules, and every later
  mode (Stage, Challenge) would have to carry the rest.
- Per-pattern generation on demand from the view's request — breaks determinism by request order.
- Continuous swept shapes — not needed at 60 Hz with a 0.6-segment ship (doc 17 recommends sweeping the
  segment range only).

## Consequences
- All rules are testable headless with seeded runs.
- Later modes reuse `SurvivalRun` with a different `RunConfig` and generator.
- Moving obstacles (next target) extend `ObstacleField` and the collision test.
