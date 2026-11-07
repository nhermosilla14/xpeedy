# 0006. Rollers and bouncers

- Status: Done
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0020, 0021

## Goal
The two moving obstacles of the original (doc 04) exist in Survival: **rollers** that tumble sideways from
lane to lane and **bouncers** that slide up and down away from their tile, placed by the moving variants of
the patterns. Casual, Easy, Standard and Extreme have them; Pure does not (doc 10). The user said "go on"
after the menus intent; the agent accepted this intent, its ADRs and slices on that go-ahead, and the user
reviews the result.

## Acceptance criteria
- **Rollers** (doc 04): a roller turns at (290 − TPS) degrees per second, a step is 60° inside, 90° flat and
  120° outside, then it rests 200 ms. It keeps one direction, wrapping around a tube and reversing at lane 0
  and 15 on a flat part. Its danger area follows its step progress (current lane under 30 %, both lanes
  30–70 %, destination lane over 70 %). Each landing near the ship gives a 100 ms camera shake.
- **Bouncers**: the distance from the surface follows a sine wave between 0 and about 1.57 units (the tube's
  far side inside a tube) with half-period 1000 − 4 × (TPS − 100) ms. A bouncer is dangerous on its own lane
  only while within about 0.29 units of the surface, and inside a tube also on the opposite lane when it is
  near the far side.
- **Smashing**: a roller or bouncer needs one shield, gives +200, and explodes where it is at that moment.
  Without a shield it is a crash.
- **Trails**: a roller paints its danger lanes (so the trail follows it); bouncers paint none (doc 04).
- **Patterns**: the moving variants of patterns 0, 2, 3, 4, 6 and 8 (doc 04 table) appear with a 50 % chance
  when rollers or bouncers are enabled and the pattern lies before the next shape change; the other patterns
  are unchanged. With both disabled (Pure) the generated track is exactly as before.
- **Difficulty**: Casual, Easy, Standard and Extreme enable rollers and bouncers; Pure disables them.
- **Look**: they are drawn like the other obstacles (dark body, bright edges, ADR 0015) and move smoothly: a
  roller tips over the edge it shares with the next lane, a bouncer rises and falls along the surface normal.
- Determinism: the same seed, the same inputs and the same time give the same moving obstacles on every
  platform. Motion depends on the game time of the run only, so pausing freezes it.
- The existing rules and tests keep working. On the RG351P at 480×320, with `--benchmark`, every 10 s window
  keeps an average of at least 58 fps and a 1 % low of at least 50 fps; the benchmark's own track changes
  because the moving variants now occur (the new numbers are the baseline).
- The user reviews it (screenshots, and on the device).

## Out of scope
- Time Dilation freezing them (bonuses), Phase Shift and torpedoes, the "Time Paradox" and "Fire at Will"
  achievements, custom difficulty toggles, hand-designed patterns in Stage races.
- Sound for the stomp.

## Open questions
- None. Where the doc is silent (the exact shape of a bouncer's range inside a tube, pair layouts of some
  moving formations) the decisions are in ADR 0020 and are refined in the review.
