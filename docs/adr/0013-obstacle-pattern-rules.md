# 0013. Obstacle pattern generation rules

- Status: Accepted
- Date: 2026-11-06
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0003

## Context
Slice 0010 generates every static pattern of doc 04 (indexes 0–15) with their spike and wall variants,
and the difficulty progression of doc 10. The doc leaves several details open. This record fixes them so
the generator is deterministic and testable. ADR 0008 already fixes where patterns are placed (55, then
`max(8, 12 − ⌊d/300⌋)`, level `⌊d/150⌋`) and the lane rules for walls and diagonals.

## Decision

### Choosing the pattern
- **Level 0**: a single cube or a single beam, 50/50.
- **Level 1–5**: the index is uniform over 0 … `level` (inclusive).
- **Level 6 and above**: the index is uniform over 1 … `min(level, 15)`. This is how "above level 5
  the index is shifted up by one, so single cubes stop appearing" is read: index 0 (the only single
  cube) is dropped, and the full catalogue is in play from level 15 (d ≥ 2250), as doc 10 says.
- Moving alternatives (rollers, bouncers) are not generated yet; they will add their own draws.

### Variants
For an index, its formations are split into spike formations, wall formations and regular ones (doc 04
table). The choice is made in this order, each step drawing only when it applies:
1. if spikes are enabled and the index has a spike formation: chance 1/3 → one of the spike formations;
2. otherwise, if the pattern's part is FLAT or OUT and the index has a wall formation: chance 1/3 → a
   solid cube or beam wall. Walls are one segment long, so they always lie inside the part. Walls are
   never generated in IN parts;
3. otherwise one of the regular formations (a draw only if there is more than one).

With spikes disabled, patterns fall back to their other formations (doc 04).

### Formations (static versions)
| Index | Spike | Wall | Regular |
|---|---|---|---|
| 0 | — | — | one cube |
| 1 | — | — | one beam |
| 2 | — | 2-wide wall, cubes or beams (50/50) | two cubes 8 lanes apart |
| 3 | 3-wide spike wall | 3-wide cube wall | three cubes 5 apart, or a 3-step cube diagonal |
| 4 | two 2-wide spike walls opposite | — | two opposite 2-step cube diagonals |
| 5 | — | — | 2-step beam diagonal, or three cubes 3 apart |
| 6 | — | — | three cubes evenly spread, one colour or mixed |
| 7 | — | — | pendulum, or two opposite 3-step cube diagonals in two colours |
| 8 | — | — | three cubes 3 apart |
| 9 | 4-wide spike wall | 4-wide cube wall | cross, or four cubes evenly spread |
| 10 | 4-wide spike wall | 4-wide cube wall | four cubes evenly spread |
| 11 | — | — | three 2-step cube diagonals 5 apart |
| 12 | — | — | 3-step beam diagonal, or two opposite 2-step beam diagonals |
| 13 | — | — | 8-step cube diagonal (spiral) |
| 14 | — | — | two opposite 3-step cube diagonals in two colours |
| 15 | two opposite 3-wide spike walls; a 6-wide spike wall; three 2-wide spike walls 5 apart | — | six cubes evenly spread |

Where the doc is silent:
- **Pendulum**: a cube at lane l (segment 0), a beam at l + 4 (segment 1), a cube at l + 8 (segment 2),
  so it swings across a quarter and then half a ring.
- **Cross**: a beam at l (segment 0) and a beam at l + 4 (segment 1).
- **Towers** (index 12) use beams for both alternatives.
- A **diagonal** moves one lane per segment in a direction chosen 50/50. "Opposite" diagonals start 8
  lanes apart and move the same way. "n apart" starts are multiples of n lanes.
- **Evenly spread n** cubes sit at start + ⌊i·16/n⌋. For n ≤ 4 there is a 50 % chance the formation
  repeats on 1–4 consecutive segments (the count is uniform over 1–4).

### Colours
One colour per pattern, drawn once, except: the two-colour diagonals take a second colour for their
second diagonal, and "mixed" spreads draw a colour for every cube.

### Lane placement
- Wall, diagonal, pendulum and multi-wall formations ("fitting" formations) on a FLAT part pick their
  start so every lane lies in 0–15 without wrapping; on tube parts (IN, OUT) the start is any lane and
  lanes wrap modulo 16.
- Ring formations (evenly spread, "n apart", cross) pick any start and wrap modulo 16 everywhere.

### Draw order (own stream, ADR 0005)
Per pattern: level-0 kind or the index; spike chance; wall chance; regular-formation choice;
formation-specific draws (wall kind, diagonal direction, spread mixed flag and repeat); colour; extra
colours; lane start. The same seed gives the same obstacles regardless of how the world is requested.

## Alternatives considered
- Reading the index shift as "draw 0 … min(level, 15) and add one" — it would unlock the whole
  catalogue at level 14 and need an index 16, contradicting doc 10.
- Allowing walls in IN parts too — the doc ties the wall variant to flat and outside track.

## Consequences
- The catalogue is data-like (one place lists every formation), so adding rollers and bouncers later
  means adding their alternatives and their draws.
- Draw orders change whenever formations are added, so seeds are not stable across versions.
