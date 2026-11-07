# 0008. Hazard zones

- Status: Done
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0023

## Goal
The five hazard zones of doc 07 exist in Survival: Blackout, Gravity Well, Hue Shift, Dark Nebula and Plasma
Cloud. A zone mark on the track starts a 3 s countdown with a warning banner, then the zone is active for 7 s
of game time, and Space Fold can end it. The user said "go on" after the bonuses; the agent accepted this
intent, its ADR and slices on that go-ahead, and the user reviews the result. The RG351P benchmark stays
skipped at the user's request.

## Acceptance criteria
- **Marks and lifecycle** (doc 07, 10): a mark is a ring of all 16 lanes × 1 segment, painted in colours that
  hint at its zone. The first mark is at 200–400 + 3000 ÷ TPS + 1 segments, the next one that far after each
  mark. The type is drawn uniformly among the five; a disabled one is re-rolled up to 10 times, then the mark
  is skipped. Crossing a mark starts a 3 s countdown only when no zone is active and no countdown is running;
  after it the zone is active for 7 s of game time (Time Dilation slows both). Pausing freezes the timers.
- **Warning**: a banner near the top shows "zone change", the zone's name and a 3 → 2 → 1 timer; a 200 ms
  white flash at the start, at every second and when the zone ends.
- **Space Fold** ends an active zone immediately (it stays wasted during the countdown, doc 17).
- **Blackout**: a dark negative track, no trails drawn, lighter fog (0.3).
- **Gravity Well**: a sideways force added to the steering, 0.3 × g(t) with the formula of doc 07 and random
  phases drawn when the zone starts, fading out over the last second; the camera yaws 15° × g, the field of
  view narrows to 80° (from 96°) and there is a light continuous shake; the fog pulses 0.4 ± 0.1 at 2 rad/s.
  The aspect wobble is left out.
- **Hue Shift**: each lane is painted a colour that oscillates between two obstacle colours at its own rate
  (0.6–1.0 cycles per second); obstacles are drawn faint grey; fog 0.3.
- **Dark Nebula**: the track brightness pulses 0.5 ± 0.3 about every 1.3 s; obstacles are drawn as
  negatives; trails stay; fog 0.3.
- **Plasma Cloud**: vortices appear on random tiles ahead (one every 5–9 segments after the last), at most 7,
  6, 4 or 3 alive for a target speed of ≥ 133, ≥ 100, ≥ 80 or less; touching one costs a shield if there is
  one, discards the held bonus and never crashes; a pale blue pulsing glow covers the screen and the camera
  shakes lightly; all vortices vanish when the zone ends. A vortex is drawn as a pulsing blue tile (not a
  particle fountain).
- **Difficulties**: Casual, Easy, Standard and Extreme use all five zones; Pure only Blackout (doc 10).
- Determinism: the marks, their types and the Gravity Well and vortex draws depend on the seed only (own PRNG
  streams); decoration shake uses the camera's own generator. With zones off the track is exactly as before.
- The existing rules and tests keep working.
- The user reviews it (screenshots).

## Out of scope
- Particle fountains for plasma, the aspect-ratio wobble, Phase Shift protection, stage marks, sound and
  vibration, and doc 07's zones in Stage mode.

## Open questions
- None. Where the doc is silent (what a vortex does after being touched: it vanishes) the decision is in ADR 0023.
