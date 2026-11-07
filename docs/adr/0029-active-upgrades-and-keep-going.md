# 0029. Active upgrades, the HUD buttons and keep going

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to go on), agent
- Intent: 0010

## Context
Doc 08 describes three active upgrades with buttons on the left edge, and doc 13 "keep going" after a crash.
The run model is stepped by game-time `dt`, so every timer they need freezes with pause and slows with Time
Dilation like the others; doc 17 recommends exactly that.

## Decision
- **Run state in `SurvivalRun`** (all from `RunConfig`: `recharger_level`, `torpedo_level`, `phase_level`,
  zero when absent): `recharger_used`; `torpedoes_left`, `torpedo_ready_at` (the ship segment at which the
  next one is reloaded) and the flying `torpedoes` list; `phase_used` and `phase_left` (game seconds).
  - `use_recharger()`: adds the level in shield units (`shields.add()` that many times, at least once so the
    timer restarts), marks it used, emits `RECHARGED`.
  - `fire_torpedo()`: needs `torpedoes_left > 0` and `track.segment ≥ torpedo_ready_at`; launches a torpedo at
    the ship's lane position and segment, decrements, and sets `torpedo_ready_at = segment + 100 / 1.25^level`
    while torpedoes remain. Each tick a torpedo advances by twice the ship's travel of that tick and is removed
    25 segments ahead of the ship. It destroys every alive obstacle whose tile range ± 0.4 it touches (lanes by
    the danger lanes of the obstacle at that time, with the seam wrap, so a tube beam is hit at both ends)
    with no points and no shield cost, and emits `TORPEDO_FIRED` and one `TORPEDO_HIT` per obstacle.
  - `use_phase_shift()`: sets `phase_left` to 5 or 10 s, marks it used, emits `PHASE_STARTED`; while it is above
    zero obstacles and plasma vortices are ignored in `_resolve_obstacles` and `_resolve_vortices`; events
    `PHASE_WARNING` at 2 s and 1 s left and `PHASE_ENDED`.
  - `continue_run()`: allowed once, after an obstacle crash only (`crash_reason == "obstacle"`); it clears the
    crash, fires the Quake effect and emits `CONTINUED`. The Game Over flow offers it (see below).
- **Input**: actions `recharge`, `torpedo`, `phase` (keys Q, W, E; gamepad X, Y, R1, which `InputLayout` does
  not touch) and touch or click on the buttons. `main.gd` calls the run methods and refuses them while paused,
  crashed, finished or in a menu.
- **HUD**: `Hud` draws a stack of buttons on the left edge below the held-bonus ring, from the top: Recharger,
  Torpedo (with a clock dial for the reload and the count left), Phase Shift; each only while usable; a press
  emits `upgrade_pressed(kind)`. Phase Shift also dims trails (a `phase` global shader uniform) and draws
  obstacles faint. A torpedo is drawn as a bright projectile (a small instanced quad by the obstacle view).
- **Keep going**: after an obstacle crash, the flash plays, and if `run.can_continue()` and the balance is at
  least 2 the panel "keep going?" shows "continue for 1 cr" and "no"; yes spends the credit and calls
  `continue_run()`; no shows Game Over. Wall crashes and a second crash go straight to Game Over.
- **Upgrades shop** (`MenuController` page `UPGRADES`): items from the catalogue with a progress bar of levels,
  the next price or "max" as count, a padlock when the next level is locked, the balance as a footer; confirm
  buys. The run finished and stage finished panels get an "upgrades" choice when `any_buyable`.

## Alternatives considered
- Ticking the torpedo reload by real time — the doc measures it in travel time and pause must freeze it.
- Making keep going a separate scene — it is one more panel on the same flow.

## Consequences
- Achievements (Sharpshooter, Fire at Will, Time Paradox) can later count `TORPEDO_HIT` events.
- The shop and the buttons have no icons, only names; icons come with the art pass.
