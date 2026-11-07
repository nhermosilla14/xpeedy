# 0003. Survival core: obstacles, shields and score

- Status: Done
- Date: 2026-11-06
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0008, 0009 (superseded), 0010 (superseded), 0011, 0012, 0013

## Goal
A player can play an endless Survival run at Standard difficulty on the tunnel built in intents 0001
and 0002: obstacles come at them, coloured trails warn them, shields let them smash through, and the
run ends in a crash. They can see their score and shields, and restart. The behaviour follows
reference docs 04, 05, 09 and 10 (static obstacles only), and the shield spots of doc 06.

## Acceptance criteria

### Obstacles and patterns (doc 04, 10)
- Three static obstacle types exist: **cube** (1 tile), **beam** (inside a tube it spans its lane and
  the lane + 8; on flat and outside parts it sticks up like a pole) and **spike** (a short pyramid on
  one tile). Each takes one of the five documented colours unless the pattern says otherwise.
- Patterns are generated as in the doc 04 table for indexes 0–15, in their static versions
  (including the spike variant at 1 in 3 and the wall variant at 1 in 3 on flat or outside parts
  before the next shape change). Moving alternatives are not generated.
- Survival placement follows doc 10: first pattern at segment 55, spacing max(8, 12 − ⌊d/300⌋),
  complexity level ⌊d/150⌋, patterns only inside the 50-segment horizon.
- The same seed gives the same obstacles and spots, regardless of how the world is requested.

### Warning trails (doc 04)
- Cubes, beams and spikes paint a trail on their lane in the 25 segments before them: invisible
  beyond 25 segments, fading in linearly over the next 10 segments of approach from the track colour
  to the obstacle's colour.
- Within 15 segments, the trail on or next to the ship's lane shifts towards red-orange (0.94, 0.12,
  0.05), from nothing at 15 segments to full at 5, scaled by √(1.5 − d) with d the lateral distance in
  lanes (none beyond 1.5 lanes).
- Beams inside a tube also paint the opposite lane, scaled by how tube-shaped the track is.

### Collisions and shields (doc 04, 05)
- The ship's hit box is 0.6 segments long and ±0.25 lanes wide; obstacles occupy their tile.
  Seam wrap applies in tubes when not morphing; beams inside tubes also hit the opposite lane, during
  a morph only while the tunnel is at least 80 % tube-shaped.
- Shield rules: start with 0, maximum 4; cube and spike cost 1 shield and give +100; a beam costs 2
  and gives +300; with too few shields, touching an obstacle is a crash. Several smashes can happen in
  one tick. Collision is tested over the whole distance covered since the previous tick.
- A single decay timer of 20 s removes one shield on expiry and restarts; it restarts whenever a
  shield is picked up (even when full), and when a shield is lost to a collision.
- Shield spots (1 lane × 3 segments, orange) are generated as in doc 10: first group at segment 100,
  next after 3·s + random(0…s−1) segments, 1-in-8 groups skipped, group size 1 + random(0…⌊d/450⌋)
  capped at 3, spread evenly around the ring. Flying over one adds a shield, once per spot. (All spots
  are shields in this target, since bonuses are not implemented yet.)
- An obstacle crash ends the run, with the same camera pitch-up as a wall crash. There is no
  "keep going" offer yet.

### Score and feedback (doc 09, 15)
- Score: +1 per segment travelled while the run is in progress, plus the smash points. It never goes
  below 0 and restarts at 0 with each run.
- The screen shows the score (bottom left) and one slot per possible shield (bottom right), with the
  filled slots showing the decay level.
- Smashing an obstacle plays a visible explosion of fragments in its colour plus a pink-white flash
  (300 ms); picking up a shield spot gives an orange flash (300 ms); a crash gives a white flash
  (1000 ms), as in doc 15.
- The existing restart control starts a new run.

### Performance (ADR 0002, intent 0002)
- On the RG351P at 480×320, during a run with obstacles, trails and spots on screen, the 10-second
  windows keep an average ≥ 58 fps and a 1 % low ≥ 50 fps. The measured result is recorded.

## Out of scope
- Rollers, bouncers and the moving pattern variants (next target).
- Bonuses (Quake, Time Dilation, Space Fold), hazard zones, upgrades, torpedo, Phase Shift.
- "Keep going", credits and the economy.
- Menus, difficulty selection, start lights, pause, sound, music, vibration, saved personal bests.
- Stage mode and hand-designed patterns.
- Fonts and art polish beyond readable defaults.

## Open questions
- None. Decisions taken with the user: static obstacles only in this target; Standard difficulty only
  (the run configuration is built so other difficulties are just different values).
