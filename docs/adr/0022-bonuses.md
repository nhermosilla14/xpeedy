# 0022. Bonuses: spot kinds, the held bonus and the effects

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to continue), agent
- Intent: 0007

## Context
Doc 06 and 10 define three bonuses that are picked up from spots, held one at a time and fired by the player.
Shield spots exist (ADR 0008) and are painted into the trail texture's alpha channel as a flag (ADR 0011).
The game clock already scales (`RunClock.scale`), and rollers and bouncers move with `game_time` (ADR 0020).

## Decision
- **`Spot.Kind`** `{ SHIELD, QUAKE, TIME_DILATION, SPACE_FOLD }` (default shield). `SpotField` takes the three
  bonus flags (default off, so older tracks do not change). In each spot of a group, after the start lane, and
  only when at least one bonus is enabled: Quake draw (1/10, or 1/5 from segment 751); if not Quake and the
  point is beyond segment 300: Time Dilation draw 1/6, then Space Fold draw 1/6; a disabled bonus becomes a
  shield. Draws are always made when any bonus is enabled, so a custom difficulty keeps one stream.
- **Texture**: the A byte of a tile is 0 (no spot) or `(kind + 1) × 60`; `TrailMap.texel().a` returns `kind +
  1` (1.0 for a shield, as before). The tunnel shader paints bonus spots in the colours of doc 06 over the
  same dotted mesh.
- **Held bonus**: `SurvivalRun.held` (`Bonus.NONE, QUAKE, TIME_DILATION, SPACE_FOLD`). Collecting a bonus spot
  sets it when empty and emits `BONUS_PICKUP`; when full the spot is used up silently. `RunConfig` has three
  flags (`quake_enabled`, `dilation_enabled`, `fold_enabled`, default false); difficulties turn them on except
  Pure.
- **Firing**: `SurvivalRun.fire()` applies the held bonus and empties it; `main.gd` calls it for the `fire`
  action (Space, Enter, gamepad A) and for a click or tap on the HUD outside the pause button. It is ignored
  while paused, crashed or in a menu.
  - **Quake**: every alive obstacle in `[window_start, window_start + 50)` is destroyed (`destroy` and
    `trails.remove_obstacle`), without points or shield cost. The event carries the 8 nearest to the ship for
    the explosions; the view flashes (1.0, 0.8, 0.5) for 800 ms.
  - **Time Dilation**: `dilation_left = 7.0` (game seconds, decreasing by each tick's `dt`, which is already
    scaled), and `time_scale()` returns 0.75 while it is above zero; `main.gd` copies it to `RunClock.scale`
    before each step. `game_time`, the clock of rollers and bouncers, does not advance while it is active.
    Firing again resets the 7 s. Events `DILATION_STARTED` and `DILATION_ENDED` drive the blue flashes and
    the tint (a `ColorRect` that shows while active).
  - **Space Fold**: ends the active zone, if any. There are no zones yet, so it only empties the hand; the
    zones intent will hook in here.
- **HUD**: `Hud` draws a pulsing ring at the top-left in the held bonus colour (`Hud.update` reads `held`).

## Alternatives considered
- Spot kinds as separate texture channels — no room in RGBA8; the alpha byte holds the kind.
- Scaling `Engine.time_scale` for Time Dilation — it would also slow the menus, the camera and the flashes;
  the game clock already exists for this.
- Firing from the HUD only — the keyboard and gamepad need it too.

## Consequences
- The hazard zones intent adds Space Fold's effect and the plasma vortex that throws the held bonus away.
- Stage mode will give races their own bonus flags through the same `RunConfig` fields.
- Shield spots and bonus spots share a collision path, so spot tests stay valid.
