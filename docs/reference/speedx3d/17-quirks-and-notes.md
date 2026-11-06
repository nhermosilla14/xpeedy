# 17 – Quirks and reimplementation notes

Behaviour of the original that is buggy, frame-rate dependent or surprising. For each item, decide
whether to reproduce it faithfully or fix it. The recommendation is in **bold**.

## Bugs in the original

| # | Quirk | Recommendation |
|---|---|---|
| 1 | **Tachyon Boost does nothing.** It is sold and described as "−25 % reload per level", but the reload speed actually scales with the *Tachyon Torpedo* level. | **Fix**: reload factor = 1.25^(Tachyon Boost level); torpedo count = Tachyon Torpedo level. |
| 2 | The upgrade descriptions say Flow Control slows the game 10 % / 25 %. The real factors are 0.87 → 0.95 → 1.09, which is about 8 % / 20 % slower relative to the default. | Keep the numbers, fix the text. |
| 3 | The help text says shields max at "three, or four with the upgrade". In fact Survival always allows 4, and Stages and Challenges allow 3–5. | Follow the actual behaviour ([05](05-shields-and-collisions.md)). |
| 4 | Space Fold fired outside an active zone, including during the 3-second countdown, is wasted. | Optional: let it cancel a pending countdown. |
| 5 | Picking up a bonus while already holding one destroys the spot without effect. | Faithful; a shimmer or sound cue would help. |
| 6 | Range values in race files exclude the upper bound, so `1-3` never yields 3. | Faithful, otherwise the race data's balance changes. |
| 7 | Game-over in a Stage race wipes the stage's running score, but the race counter is kept. | Faithful. It is the stage's "no-death" scoring. |
| 8 | Torpedo, Quake and Phase Shift destroy or ignore obstacles without awarding points. | Faithful. |
| 9 | "Keep going" can be used only once per run. | Faithful, or make it explicit in the UI. |
| 10 | Normal play never earns credits, so upgrades are impossible without the defunct monetisation ([13](13-economy.md)). | **Add a gameplay reward.** |
| 11 | Pausing does not stop the shield decay, Phase Shift or torpedo reload timers. A long pause costs a shield unit on resume (at most one, since the decay is checked only while racing), can let Phase Shift expire unseen, and completes a torpedo reload. | **Fix**: freeze every gameplay timer while paused. |

## Frame-rate dependencies

1. **Acceleration ramp**: each frame, the original reduces TPS by *a* × *dt* × 10, where *a* starts at
   (300 − target) / 10, and then decreases *a* by 0.1. The ramp therefore depends on frame rate,
   although at 30–60 fps it reaches top speed in about 1 s either way.
   **Recommended time-based replacement**: ease TPS from 300 to the target over 1.0 s of game time,
   with an ease-out curve (fast at first, gentle at the end).
2. **Camera banking smoothing** blends with min(1, 5 × *dt*): fine, it is already time-based.
3. **Tilt filter**: the low-pass filter runs once per sensor event, not per frame, so its feel depends on
   the sensor rate (about 50–60 Hz on most phones). Run it at a fixed 60 Hz in a reimplementation.
4. **Frame-time cap**: frames longer than 200 ms are replaced by the previous frame's duration. Keep a
   similar cap so a stall never moves the ship through obstacles.
5. **Collision sampling**: collisions are tested once per frame at the ship's current position, so at
   very low frame rates a fast ship could step over a 1-segment obstacle. The 0.6-segment ship length
   reduces this. **Test against the swept segment range** for robustness.

## Determinism

- Survival, and races without a `seed`, are seeded from the clock.
- Challenges and seeded races need the same generator sequence on both sides. The original used the
  platform's standard pseudo-random generator, consuming values in a fixed order for track shapes,
  path curvature, obstacles, spots and zones.
- A reimplementation that wants seeded runs to be shareable between platforms must define its own
  portable generator, and a fixed order of random draws.
- Pure decoration (zone colours, camera shake, particles) should use a separate generator so it never
  disturbs the gameplay sequence.

## Scale and performance hints

- Only 50 segments × 16 lanes are ever live: 800 tiles, with up to about 150 obstacles and 150 spots
  at once. Small fixed pools are enough.
- The tunnel mesh is a 51 × 17 vertex grid, regenerated incrementally as segments scroll. Shape morphs
  change every vertex of the visible mesh each frame for 30 segments, which is cheap at this size.
- Generation (new segments, new patterns) can run on a background thread, as in the original, or simply
  between frames. The work per frame is tiny.

## Things that are safe to drop or replace

- Zeemote controller support. Replace with gamepad support: left stick = steer, A = bonus, Start = pause.
- Online challenges: replace with local "ghost" challenges (same seed, compare with a saved score), or a self-hosted service.
- Achievements and leaderboards: local equivalents ([09](09-scoring-and-records.md)).
- Ads, offer walls, "remove ads", sponsor logos and "More games".
- Anaglyph stereoscopy (optional novelty).

## Suggested additions for new platforms

- Touch steering (hold the left or right screen half), keyboard (arrows / A–D), mouse and gamepad,
  all feeding the same response curve ([03](03-movement-and-controls.md)).
- A tilt-free calibration step on desktop.
- Window resize and aspect-ratio handling: the original assumes a landscape phone and scales the HUD by screen height ÷ 320.
