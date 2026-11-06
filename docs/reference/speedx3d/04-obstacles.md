# 04 – Obstacles

Obstacles sit on the tile grid (segment × lane). Touching one ends the run, unless the player has
enough shields to smash it ([05](05-shields-and-collisions.md)).

## Obstacle types

| Type | Shape and behaviour | Shields needed to smash | Points for smashing |
|---|---|---|---|
| **Cube** (block) | A cube filling one tile, one segment tall. | 1 | +100 |
| **Beam** | A long bar about 1.96 units long. Inside a tube it spans the tube's diameter, from its lane to the **opposite lane** (lane + 8). On flat and outside parts it sticks up from the surface like a pole. | **2** (with only 1 shield, a beam is still a crash) | +300 |
| **Spike** | A short pyramid about a quarter of a beam's height, on one tile. | 1 | +100 |
| **Roller** | A cube that **tumbles sideways** from lane to lane. | 1 | +200 |
| **Bouncer** | A cube that **slides up and down** away from its tile; inside a tube it crosses to the opposite side and back. | 1 | +200 |

Obstacles take one of five colours at random, unless the pattern specifies otherwise:
amber `#FBAF02`, green `#38C36D`, lime `#94C137`, teal `#47B4B3`, mauve `#A95795`.

### Rollers

- A roller tips over the edge it shares with the next lane. It turns at (290 − TPS) degrees per second,
  so faster runs have faster rollers.
- One step is complete when it has turned through 60° (inside), 90° (flat) or 120° (outside). It then
  rests on the new lane for 200 ms before the next step.
- It keeps one direction. Inside or outside a tube it wraps around the circumference. On a flat part
  it reverses when it reaches lane 0 or lane 15.
- Danger area during a step (progress = angle turned ÷ step angle):
  - under 30 %: only its current lane;
  - 30 %–70 %: both its current and its destination lane;
  - over 70 %: only its destination lane.
- Each landing gives a 100 ms camera shake (a "stomp").
- Rollers freeze in place during Time Dilation.

### Bouncers

- A bouncer moves along the surface normal of its tile. Its distance from the surface follows a smooth
  sine wave between 0 and about 1.57 units, with half-period **1000 − 4 × (TPS − 100) ms**.
- It is dangerous on its own lane only while close to the surface (within about 0.29 units). Inside a
  tube it is also dangerous on the **opposite lane** when it is near the far side. On flat and outside
  parts it just rises into the air, and the lane is safe while it is up.
- Groups of bouncers are usually phase-staggered by 150 ms per segment, giving a wave pattern.
- Bouncers freeze in place during Time Dilation.

## Hit boxes

- The ship is treated as **0.6 segments long** and **0.5 lanes wide** (±0.25 lanes around its position).
- An obstacle occupies its tile: lanes [*lane*, *lane* + 1) and segments [*seg*, *seg* + 1).
- They collide when the ship's segment is within [*seg* − 0.6, *seg* + 1] and the ship's lane position is
  within [*lane* − 0.25, *lane* + 1.25].
- **Seam wrap**: in a tube, when not morphing, an obstacle on lane 0 also catches a ship at lane
  position ≥ 15.75, and an obstacle on lane 15 catches a ship below 0.25. On flat parts and during
  morphs there is no wrap.
- **Beams inside a tube** also occupy the opposite lane (lane + 8). During a morph this extra hit area
  exists only while the tunnel is still at least 80 % tube-shaped: morph ≤ 20 % when leaving *in*, or
  ≥ 80 % when entering *in*.

## Trails (warning stripes)

Every cube, beam, spike and roller paints a coloured **trail** on its lane in the 25 segments
leading up to it. This is the player's main way of reading what's ahead.

- The trail becomes visible once the obstacle is less than 25 segments ahead. Its colour fades in
  linearly over the next 10 segments of approach, from the base track colour to the obstacle's colour.
- **Proximity highlight**: when the obstacle is 15 or fewer segments ahead, the trail on (or next to)
  the ship's lane shifts towards **red-orange** (RGB ≈ 0.94, 0.12, 0.05).
  - The strength grows from nothing at 15 segments ahead to full at 5 segments ahead.
  - It also depends on how close the ship is laterally: √(1.5 − *d*), where *d* is the ship's distance
    in lanes from the centre of the trail's lane. Beyond 1.5 lanes there is no highlight.
- Beams inside a tube also paint the opposite lane, scaled by how tube-shaped the track currently is.
- Rollers paint both their current and their destination lane, weighted by how far the current step has progressed.
- Bouncers paint no trail.
- During Phase Shift the trails stay at half strength with no red highlight. During Blackout trails
  are not drawn at all ([07](07-hazard-zones.md)).
- The last 5 segments before a race's finish line darken to black over 10 segments.

## Placement: obstacle patterns ("constructs")

Obstacles are placed as **patterns**, at intervals along the track:

- Each time a pattern is placed, the next placement point moves forward by
  *spacing* × (*lock* + 1) segments.
  - *spacing* comes from the mode: [10](10-survival-mode.md) and [11](11-stage-mode.md).
  - *lock* is 0 for the generated patterns below, but hand-designed patterns can set it higher to
    reserve extra empty track after themselves.
- Patterns are generated only for segments inside the 50-segment horizon.

### Generated patterns by complexity level

Every random pattern is chosen given a **level** (0–15+), which comes from distance in Survival or
from the race file in Stages. Higher levels unlock larger patterns:

- **Level 0**: a single cube or a single beam (50/50).
- **Level ≥ 1**: pick an index uniformly from 0 to min(level, 15). Above level 5 the index is shifted
  up by one, so single cubes stop appearing.

Some patterns have variants, chosen at random per placement:

- **Spike variant**: if spikes are enabled, there is a 1-in-3 chance of using a spike formation where one exists.
- **Wall variant**: on flat or outside track, before the next shape change, there is a 1-in-3 chance of
  using a solid side-by-side wall where one exists.
- **Moving variant**: if rollers or bouncers are enabled and the pattern sits before the next shape
  change, patterns 0, 2, 3, 4, 6 and 8 have a 50 % chance to become moving formations instead
  (see the last column).

| Index | Static pattern | Moving alternative |
|---|---|---|
| 0 | Single cube | One bouncer or one roller |
| 1 | Single beam; without beams, a 2-wide wall or two cubes on opposite sides | — |
| 2 | A 2-wide wall (cubes or beams), or two cubes 8 lanes apart | Two bouncers on consecutive segments of one lane, or two rollers turning opposite ways |
| 3 | 3-wide spike wall, 3-wide cube wall, three cubes 5 lanes apart, or a 3-step diagonal of cubes | Three rollers turning alternate ways, or three bouncers in a column |
| 4 | Two 2-wide spike walls on opposite sides, or two opposite 2-step cube diagonals | Two bouncers 4 lanes apart, staggered by 500 ms (not on outside track), or a 2–3 roller column moving together |
| 5 | A 2-step diagonal of beams, or three cubes 3 lanes apart | — |
| 6 | Three cubes evenly spread around the ring, in one colour or mixed | A snake of 3–6 rollers on consecutive segments, 100 ms apart, all turning the same way |
| 7 | "Pendulum": a cube, a beam on the next segment, then a cube on the opposite side; or two opposite 3-step diagonals in two colours | — |
| 8 | Three cubes 3 lanes apart | Two pairs of rollers moving together, the pairs 2 segments apart and turning opposite ways |
| 9 | "Cross": two beams 4 lanes apart on consecutive segments; or a 4-wide spike or cube wall; or 4 cubes evenly spread | — |
| 10 | A 4-wide spike wall, a 4-wide cube wall, or 4 cubes evenly spread | — |
| 11 | Three 2-step cube diagonals 5 lanes apart | — |
| 12 | "Three towers": a 3-step diagonal of beams; or two opposite 2-step diagonals | — |
| 13 | "Spiral": an 8-step diagonal of cubes over 8 segments | — |
| 14 | Two opposite 3-step diagonals in two colours | — |
| 15 | "Six": two opposite 3-wide spike walls, a 6-wide spike wall, three 2-wide spike walls 5 lanes apart, or 6 cubes evenly spread | — |

Notes:

- "Evenly spread *n* cubes" starts at a random lane, every 16/*n* lanes. A spread of 4 cubes or fewer
  may (50 % chance) repeat over 1–4 consecutive segments, forming a tube-long pillar ring. Beam spreads may repeat over 1–2 segments.
- A "diagonal" of *n* places one obstacle per segment, shifting one lane each segment.
- Moving patterns are placed only before the next shape change. A shape change would alter how they move.
- Where an obstacle type is disabled (for example beams), patterns fall back to cube-based variants.

### Hand-designed patterns (Stage races)

Race files can define custom patterns as a grid of 16 lanes × *n* segments, each cell empty, cube,
beam or spike, with optional per-cell colours. Each one is placed once, at the first pattern point
strictly after its minimum segment, instead of a generated pattern. See [11](11-stage-mode.md).
