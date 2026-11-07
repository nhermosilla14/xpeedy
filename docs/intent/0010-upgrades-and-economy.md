# 0010. Upgrades and economy

- Status: Accepted
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0028, 0029

## Goal
Permanent upgrades bought with credits (doc 08, 13) so that progress in Stage mode makes the player stronger:
six upgrades with their levels, prices and unlock schedule, an upgrades shop in the menu, credits earned by
playing, the three active upgrades in a run (Shield Recharger, Tachyon Torpedo, Phase Shift) and "keep going"
after a crash. The user asked for this intent and to ignore Tachyon Boost, which does nothing in the original,
so it is not built. The agent accepted this intent, its ADRs and slices on that instruction, and the user
reviews the result. The RG351P benchmark stays skipped at the user's request.

## Acceptance criteria
- **Catalogue and prices** (doc 08): Flow Control (2 levels, 15 and 30 Cr), Fractal Shields (3: 15, 20, 35),
  Shields Modulator (2: 25, 40), Shield Recharger (3: 20, 25, 35), Tachyon Torpedo (3: 15, 30, 45), Phase Shift
  (2: 25, 55); 430 Cr to max everything. Levels are bought in order.
- **Unlocks**: a level is buyable only when unlocked by the total number of distinct races ever completed in
  Stage mode (doc 08 table: Recharger 2 at 7, Fractal 2 at 12, Phase Shift 1 at 15, Flow Control 2 at 20,
  Fractal 3 at 24, Torpedo 2 at 26, Modulator 2 at 33, Phase Shift 2 at 36, Torpedo 3 at 40, Recharger 3 at 42;
  the rest from the start). The counter never goes down; a new race finished counts once.
- **Credits**: one balance (gained minus spent, never negative), saved on the device. The original's sources
  are gone, so credits are earned by playing: finishing a new Stage race gives 2 + the stage number (3 to 6),
  finishing a stage gives 10 more, and a Survival run gives 1 per 500 points when it ends. Keep going costs 1.
- **Where upgrades apply** (doc 08): Stage races, all; Survival Casual, Easy and Standard, all but Flow Control
  and Shields Modulator; Extreme and Pure, none.
- **Passive effects**: Flow Control sets the stage speed factor to 0.87, 0.95 or 1.09 (the race's speed times
  it); Fractal Shields sets the shield decay to 20, 21, 23 or 25 s; Shields Modulator sets the maximum shields
  in Stage races to 3, 4 or 5 (Survival keeps 4).
- **Active effects** (doc 08): buttons on the left edge of the HUD, stacked from the top and shown only while
  usable, also reachable with a key and a gamepad button.
  - Shield Recharger: once per run, adds 1, 2 or 3 shields (to the maximum) and restarts the decay timer even
    when full.
  - Tachyon Torpedo: 1, 2 or 3 per run; it flies down the tunnel at twice the ship's speed along the lane the
    ship was on, until 25 segments ahead, destroying every obstacle within ±0.4 lanes and 0.4 segments of its
    path (beams also at the opposite end inside a tube) for no points and no shields; the next one reloads for
    100 ÷ 1.25^level segments of travel, shown as a dial on the button.
  - Phase Shift: once per run, for 5 or 10 s of game time obstacles and plasma are ignored (spots still work),
    obstacles are drawn faint and trails dimmed with no red highlight; white flashes at 2 s and 1 s left and at
    the end.
- **Keep going**: after an obstacle crash (not a wall crash), once per run, when the balance is at least 2 a
  dialog offers to continue for 1 Cr; yes spends it, fires a Quake and the run resumes on the spot, no
  ends the run.
- **Shop**: the main menu has "upgrades" listing the six upgrades with their level, the price of the next level
  or "max", a padlock when the next level is locked, and the credit balance; the confirm button buys. The run
  finished and stage finished panels offer "upgrades" when something is buyable.
- Passive upgrades and timers respect pause and Time Dilation like every other game timer.
- Existing behaviour without upgrades or credits is unchanged, tests keep passing.
- The user reviews it (screenshots).

## Out of scope
- Tachyon Boost, the "upgrade unlocked" toast and the suggestion after five crashes, achievements (Sharpshooter,
  Fire at Will, Time Paradox), vibration and sound, Custom difficulty, the torpedo's ribbon-tail particles
  (a plain bright projectile instead).

## Open questions
- None. The credit amounts are ours; the original gave none during play.
