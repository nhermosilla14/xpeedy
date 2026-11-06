# 07 – Hazard zones

Hazard zones are 7-second modifiers that make the run harder, visually or physically.

## Lifecycle

1. A **zone mark** (a full ring of all 16 lanes, 1 segment long) appears on the track. Its colours hint at the zone type.
2. Crossing it starts a **3-second countdown**, but only if no zone is active and no countdown is
   running. Otherwise the mark does nothing.
   - On start: a warning sound, a 50 ms vibration and a short white flash.
   - A banner near the top of the screen shows a "zone change" warning, the zone's name and a 3 → 2 → 1
     timer. A 200 ms white flash marks each second.
3. When the countdown reaches zero, the zone becomes **active for 7 seconds** (game time).
4. When it ends: a white flash, and the world returns to normal.
5. **Space Fold** ([06](06-bonuses.md)) ends an active zone immediately.

Pausing freezes the zone timer.

## The five zones

### Blackout

Mark colours: amber and magenta.

- The tunnel is drawn with a dark, "negative" track texture.
- **Obstacle trails are not drawn**, so obstacles are seen only when they are close.
- Fog is lighter than normal (density 0.3 instead of 0.5).

### Gravity Well

Mark colour: translucent white.

- A sideways **force** pushes the ship. With *t* in seconds since the zone started, and random phases
  φ₁ and φ₂ chosen when the zone begins:
  *g*(*t*) = 0.25 × [2.5·sin(2.5*t* + φ₁) + 1.5·sin(1.5*t* + π/4 + φ₂)]
- 0.3 × *g* is added to the steering input every frame, so the player must counter-steer.
- During the last second the force fades linearly to zero.
- Visual distortion: the camera yaws by 15° × *g*, the field of view narrows to 80° (from 96°), and the
  aspect ratio wobbles by +0.4 × *g*.
- Fog density pulses: 0.4 ± 0.1 at 2 rad/s.
- Continuous light camera shake.

### Hue Shift

Mark colour: dark green.

- Each of the 16 lanes is painted a colour that oscillates between two random obstacle colours, each
  lane at its own rate (0.6–1.0 cycles per second). The tunnel becomes a shifting rainbow and
  **obstacle trails are lost in it**.
- Obstacles are drawn as faint, almost transparent grey (80 % grey at 20 % opacity).
- Fog density 0.3.

### Dark Nebula

Mark colours: violet and blue.

- The base track brightness pulses: 0.5 ± 0.3, roughly every 1.3 s.
- Obstacles are drawn with dark ("negative") textures.
- Trails are still drawn and blended against the pulsing track.
- Fog density 0.3.

### Plasma Cloud

Mark colour: pale lavender.

- **Plasma vortices** (fountains of blue particles rising from a tile) appear on random tiles, one
  every 5–9 segments ahead of the last.
- A limited number exist at a time, depending on the run's target speed:

| Target TPS | Max vortices alive |
|---|---|
| ≥ 133 (Casual) | 7 |
| ≥ 100 | 6 |
| ≥ 80 | 4 |
| < 80 | 3 |

- Touching a vortex costs **1 shield** (if any) and discards the held bonus, but never crashes the
  ship ([05](05-shields-and-collisions.md)). Phase Shift protects against vortices.
- A pale blue glow overlay covers the screen, and the camera shakes lightly.
- When the zone ends, all vortices vanish.

## Where zones come from

- **Survival**: a zone mark every 200–400 segments plus 3000 ÷ TPS + 1 segments. The type is random
  among the enabled zones ([10](10-survival-mode.md)).
- **Stages**: a fixed list of marks at given segments, or random marks at a given frequency from an
  allowed list ([11](11-stage-mode.md)).
