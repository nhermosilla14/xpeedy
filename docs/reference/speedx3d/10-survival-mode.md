# 10 – Survival mode

An endless run on a random track ([02](02-tunnel-and-world.md)). It lasts until the player crashes.
Difficulty rises with distance.

## Difficulties

| Difficulty | Target TPS | Obstacles | Zones | Bonuses | Upgrades |
|---|---|---|---|---|---|
| Casual | 133 | all types | all | all | yes (no Flow Control or Modulator) |
| Easy | 100 | all types | all | all | yes (no Flow Control or Modulator) |
| Standard | 80 | all types | all | all | yes (no Flow Control or Modulator) |
| Extreme | 67 | all types | all | all | no |
| Pure | 50 | cubes and beams only (no rollers, bouncers or spikes) | **Blackout only** | **shields only** | no |
| Custom | player's choice | toggles | toggles | toggles | no |

"All types" means cubes and beams (always on) plus rollers, bouncers and spikes. Maximum shields is
always 4 in Survival.

### Custom difficulty

The player edits a configuration in four pages:

1. **Speed**: Casual 133, Easy 100, Standard 80 or Extreme 67 ms per segment.
2. **Obstacles**: bouncers, rollers and spikes on or off (cubes and beams are always present).
3. **Zones**: Blackout, Gravity Well, Hue Shift, Dark Nebula and Plasma Cloud, each on or off.
4. **Bonuses**: Quake, Time Dilation and Space Fold, each on or off (shields are always present).

The configuration is saved. The default is speed 100 with everything enabled.

## Procedural generation rules

Let *d* be the distance in segments from the start of the run.

### Obstacles

- The first pattern is placed at segment **55**.
- **Spacing** between patterns: max(8, 12 − ⌊*d* / 300⌋) segments. It shrinks from 12 to 8 over the
  first 1200 segments.
- **Complexity level**: ⌊*d* / 150⌋, so a new pattern tier unlocks every 150 segments
  ([04](04-obstacles.md)). Single cubes stop appearing after level 5 (*d* ≥ 900). The full catalogue
  is in play from level 15 (*d* ≥ 2250).
- Rollers, bouncers and spikes appear only if enabled for the difficulty.

### Shields and bonuses

- The first spot group is at segment **100**.
- After each group, the next comes 3 × *s* + random(0 … *s* − 1) segments later, where *s* is the
  obstacle spacing above. That is about 36–47 segments early on and 24–31 later.
- Each group has a 1-in-8 chance of being skipped.
- **Group size**: 1 + random(0 … ⌊*d* / 450⌋), capped at 3. Single spots early, up to 3 later. The spots
  are spread evenly around the ring.
- What each spot contains:
  - **Quake**: 1 in 10, or 1 in 5 beyond segment 750, if Quake is enabled.
  - Otherwise, beyond segment 300: 1 in 6 **Time Dilation** and 1 in 6 **Space Fold**, if enabled.
  - Otherwise: a **shield**.
  - A bonus that is disabled becomes a shield instead.

### Zones

- The first zone mark is at about 200–400 + 3000 ÷ TPS + 1 segments: roughly 223–423 on Casual and 261–461 on Pure.
- After each mark, the next comes 200–400 + 3000 ÷ TPS + 1 segments later. The 3000 ÷ TPS part is the
  number of segments travelled in about 3 seconds, which covers the countdown.
- The zone type is chosen uniformly among the five. A disabled type is re-rolled, up to 10 times; if all
  10 picks are disabled, that mark is skipped.

### Random seed

Each Survival run is seeded from the clock. Challenge runs use a shared seed, so both players face the
same track and obstacles ([12](12-multiplayer-challenges.md)).
