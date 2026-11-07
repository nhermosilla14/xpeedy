# 0020. Rollers and bouncers: the model

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (go-ahead), agent
- Intent: 0006

## Context
Rollers and bouncers (doc 04) move, so where they are depends on time, not only on the seed. The model must
stay deterministic, the GPU draws them (ADR 0021) and the danger area must be the same on the CPU and in the
shader. Today an obstacle is a tile, collision sweeps the ship's lane range over the obstacles of each
segment, and trails are painted when an obstacle is added.

## Decision
- **Closed-form motion of the run's game time.** Positions are pure functions of `t`, the game time of the
  run (`SurvivalRun.game_time`, the sum of the steps), the obstacle's fixed parameters and the difficulty's
  target speed. Nothing integrates, so there is no drift and the shader can repeat the formulas. Pausing
  stops `t`. The speed ramp's first second is ignored: the target TPS is used throughout.
- **`Obstacle` gets `Kind.ROLLER` and `Kind.BOUNCER`** and the parameters `direction` (+1 or −1) and `phase`
  (seconds). `lane` is the roller's lane at its first step. Smash cost 1, points 200. A pure static class
  `MovingMath` holds the formulas, with unit tests:
  - Roller: step time = step angle ÷ (290 − TPS) with 60°, 90°, 120° for IN, FLAT, OUT parts; cycle = step
    time + 0.2 s; with `t' = t + phase`, step index `n = floor(t' / cycle)` and progress `u = (t' mod cycle) /
    step time` (≥ 1 means resting). Lane after `k` steps: `posmod(lane + direction·k, 16)` on tubes, and on
    flat parts a reflection on the 30-lane cycle (`x = posmod(lane + direction·k, 30)`, lane `x` if `x ≤ 15`
    else `30 − x`), which reverses at lanes 0 and 15. Danger lanes: current lane under 30 % progress, both
    lanes 30–70 %, the destination over 70 %, the new lane while resting.
  - Bouncer: distance `h(t) = (H/2)·(1 − cos(π·(t + phase)/half))` with half-period `1000 − 4·(TPS − 100)` ms
    and range `H = 1.57` on flat and outside parts, `1.96` inside a tube (the far side: the tube is 2 across
    and the beam of doc 04 spans 1.96). Own lane dangerous while `h < 0.29`; inside a tube the opposite
    lane (lane + 8) also while `h > H − 0.29`.
- **Collision** asks each obstacle for its danger lanes at the current game time (static obstacles keep
  their rule: own lane, plus the opposite lane for a tube beam). The ship's swept lane range is tested
  against them as before; the time is the end of the tick (a tick moves the ship about 0.2 segments).
- **Trails**: a roller's painted lanes are its danger lanes. `SurvivalRun` refreshes them every tick for
  rollers inside the window (`TrailMap.set_lanes`), and a bouncer paints none. This replaces the doc's
  weighting by step progress with the 30 % / 70 % lane switch.
- **Stomp**: when a roller within 12 segments ahead of the ship (or under it) finishes a step, a
  `RunEvent.STOMP` is emitted; the view shakes the camera for 100 ms.
- **Placement** (ADR 0013 order, new draw only when enabled): `RunConfig.rollers_enabled` and
  `bouncers_enabled`; the context says whether the pattern lies before the next shape change (its last
  segment within 8 of the point is in the same part). After the spike and wall draws, for indices 0, 2, 3, 4,
  6 and 8, a 50 % draw picks the moving formation, and then a per-pattern phase (0–999 ms). Disabled, nothing
  is drawn and the old sequences are unchanged. Formations (our reading of the doc's table):
  - 0: one bouncer or one roller (50/50).
  - 2: two bouncers on consecutive segments of one lane, or two rollers on consecutive segments of one lane
    turning opposite ways.
  - 3: three rollers on consecutive segments of one lane turning alternately, or three bouncers in a column
    (150 ms apart).
  - 4: two bouncers 4 lanes apart, 500 ms apart (not on outside parts, rollers instead), or a column of 2–3
    rollers moving together.
  - 6: a snake of 3–6 rollers on consecutive segments, 100 ms apart, all turning the same way.
  - 8: two pairs of rollers (lane and lane + 8 on one segment), the pairs 2 segments apart, turning opposite
    ways.
- **Difficulty table** gets `rollers` and `bouncers` flags (all true but Pure).

## Alternatives considered
- Simulating motion tick by tick — drifts with the step size and cannot be repeated in the shader.
- Weighting trails by step progress as in the doc — needs a per-tile weight channel; the lane switch is
  nearly the same and fits the existing texture.
- Separate collision lists for moving obstacles — they stay in `ObstacleField` by segment so everything that
  sweeps, smashes and forgets obstacles keeps working.

## Consequences
- The model is testable without a GPU, and the shader (ADR 0021) must match `MovingMath`.
- Tracks of difficulties with moving obstacles differ from the earlier ones for the same seed; Pure keeps
  them.
- Time Dilation later multiplies `t` for these obstacles only.
