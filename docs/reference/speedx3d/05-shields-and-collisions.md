# 05 – Shields and collisions

## Shield units

Shields are the player's hit points. The HUD shows them as a row of slots at the bottom right.

| Rule | Value |
|---|---|
| Shields at the start of a run | 0 |
| Maximum, Survival (any difficulty) | 4 |
| Maximum, Stage races and Challenges | 3 + *Shields Modulator* level (3–5) |
| Gaining a unit | Fly over an orange shield spot ([06](06-bonuses.md)), or use *Shield Recharger* |
| Losing a unit | Smashing an obstacle, touching plasma, or decay |

### Decay

Shields wear out over time:

- There is a single **decay timer** for the whole stack. It runs for 20 s by default; *Fractal
  Shields* makes it 21, 23 or 25 s ([08](08-upgrades.md)).
- When the timer expires, **one unit is lost** and the timer restarts.
- The timer **restarts whenever a shield is picked up**, *even when the stack is already full*. Grabbing
  a shield spot while full still refreshes the stack.
- It also restarts when a unit is lost to a collision or plasma, or added by the recharger.
- The HUD draws the remaining time as the fill level of the shield icons.

## Collisions with obstacles

Every frame, the ship's hit box is tested against obstacles near it ([04](04-obstacles.md)):

| Obstacle | Shields available | Result |
|---|---|---|
| Cube, spike, roller or bouncer | ≥ 1 | Obstacle explodes, **−1 shield**, points awarded |
| Beam | ≥ 2 | Beam explodes, **−2 shields**, +300 points |
| Beam | 1 | **Crash** (the single shield is not used) |
| Any | 0 | **Crash** |

On a smash: a short white flash, the "break" sound, a 50 ms vibration, and an explosion of tumbling
fragments in the obstacle's colour. Several smashes can happen in one frame if obstacles overlap.

While **Phase Shift** is active, obstacles and plasma are ignored completely: no smash, no crash, no
shield cost. Pick-up spots still work.

## Crashes

A run ends in a crash when:

1. the ship touches an obstacle it cannot smash, or
2. the ship leaves the track sideways on a flat part, or crosses the seam at a forbidden moment during
   a morph ([02](02-tunnel-and-world.md)). This is a **wall crash**.

On an obstacle crash the game first offers **"keep going"** once per run, if the player can afford
it ([13](13-economy.md)):

- Accept: a **Quake** fires automatically, clearing every obstacle in view, and the run continues.
- Decline, or can't afford it: the run ends.

A **wall crash** never offers to continue.

When the run ends there is a long white flash, a 500 ms vibration, the camera pitches up, and the
game-over menu appears ([14](14-ui-hud-and-menus.md)). Stage races also reset the stage's running
score ([11](11-stage-mode.md)).

## Plasma

Plasma vortices exist only inside the Plasma Cloud zone ([07](07-hazard-zones.md)). Touching one is
**not** a crash: it costs **one shield** if the player has any, and **discards the held bonus**. It
plays a power-down sound, a 100 ms vibration and a blue flash. Each vortex affects the ship only once.
