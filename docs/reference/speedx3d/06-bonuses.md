# 06 – Pick-up spots and bonuses

## Spots

**Spots** are glowing patches painted on the track. The ship collects one by flying over it, using the
same lane/segment test as obstacles ([04](04-obstacles.md)), including seam wrapping. A spot can be
collected only once. It stays active even during Phase Shift.

| Spot | Footprint | Colour | Effect |
|---|---|---|---|
| Shield | 1 lane × 3 segments | Orange (≈ 1.0, 0.7, 0.2) | +1 shield unit (up to the maximum) and restart the shield decay timer |
| Quake | 1 lane × 3 segments | Crimson (≈ 0.64, 0.02, 0.26) | Grants the **Quake** bonus |
| Time Dilation | 1 lane × 3 segments | Blue (≈ 0.30, 0.50, 1.0) | Grants the **Time Dilation** bonus |
| Space Fold | 1 lane × 3 segments | Green (≈ 0.47, 0.69, 0.0) | Grants the **Space Fold** bonus |
| Zone mark | all 16 lanes × 1 segment | Depends on the zone ([07](07-hazard-zones.md)) | Starts the hazard-zone countdown |
| Finish line | all 16 lanes × 1 segment | Light green | Marks the end of a race (finishing is based on distance, not on touching it) |

Spots are usually placed as a **ring group**: 1–4 spots on the same segment, spread evenly around the
circumference (every 16/*n* lanes from a random start lane). Group sizes and spacing depend on the mode
([10](10-survival-mode.md), [11](11-stage-mode.md)). Every group has a 1-in-8 chance of being skipped entirely.

## Holding and firing bonuses

- The player can hold **only one bonus**. Flying over a bonus spot while already holding one uses up
  the spot but **changes nothing**.
- On pick-up: a charge sound and a 200 ms vibration. The HUD (top-left) shows a pulsing ring in the
  bonus colour: Quake red, Time Dilation blue, Space Fold green.
- **Firing**: tap anywhere outside the pause and upgrade buttons, or press Enter, Space or the D-pad
  centre. The bonus takes effect on the next frame.
- Touching plasma throws away the held bonus ([05](05-shields-and-collisions.md)).

## Bonus effects

### Quake

- Destroys **every obstacle currently generated**: cubes, beams, spikes, rollers and bouncers in the
  50-segment horizon.
- It gives **no points** and costs no shields.
- Up to 8 explosion effects are shown, with a shockwave sound, a 300 ms vibration and an 800 ms
  warm flash (≈ 1.0, 0.8, 0.5).
- Obstacles generated afterwards (beyond the horizon) are unaffected.
- The paid "keep going" continue works by firing a Quake ([13](13-economy.md)).

### Time Dilation

- The **game clock runs at 75 %** of real time. Everything slows down: forward motion, timers, zone
  durations and shield decay.
- **Rollers and bouncers freeze** in place.
- It lasts **7 seconds of game time**, about **9.3 real seconds**.
- A blue tint (≈ 0.3, 0.3, 1.0 at 20 % opacity) covers the screen while active. Starting and ending
  produce a blue flash (1 s start, 300 ms end).
- Firing it again while active restarts the 7 s.
- Steering also runs on the game clock, so sideways control per segment is unchanged; the player
  simply has more real time to react.

### Space Fold

- If a hazard zone is **currently active**, it ends immediately.
- If no zone is active, **including during the 3-second warning countdown**, the bonus is consumed
  and does nothing.
