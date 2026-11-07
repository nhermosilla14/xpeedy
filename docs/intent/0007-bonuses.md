# 0007. Bonuses: Quake, Time Dilation and Space Fold

- Status: Accepted
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0022

## Goal
The three bonuses of doc 06 exist in Survival: they come as coloured pick-up spots next to the shield spots,
the ship holds one at a time, and the player fires it with Enter, Space, the gamepad's A or a tap. The user
asked to continue with "the next missing things"; the agent accepted this intent, its ADR and its slices on
that instruction, and the user reviews the result.

## Acceptance criteria
- **Spots** (doc 06, 10): bonus spots are 1 lane × 3 segments like shield spots, in crimson (Quake), blue
  (Time Dilation) and green (Space Fold). In each spot of a group: Quake with chance 1 in 10 (1 in 5 beyond
  segment 750); otherwise beyond segment 300 Time Dilation 1 in 6 and Space Fold 1 in 6; otherwise a shield.
  A bonus that the difficulty disables becomes a shield. Pure has no bonuses (shields only); the other
  difficulties have all three.
- **Holding**: one bonus at a time. Flying over a bonus spot while holding one uses the spot up and changes
  nothing. The HUD shows a pulsing ring in the bonus colour at the top-left (Quake red, Time Dilation blue,
  Space Fold green) while one is held.
- **Firing**: Enter, Space, gamepad A, or a tap or click anywhere outside the pause button. It takes effect on
  the next tick and empties the hand. Nothing happens when no bonus is held.
- **Quake**: destroys every obstacle in the 50-segment horizon without points or shield cost, with up to 8
  explosions (the nearest) and an 800 ms warm flash. Obstacles generated afterwards are unaffected.
- **Time Dilation**: the game clock runs at 75 % for 7 s of game time (about 9.3 real seconds): forward
  motion, steering, shield decay and every timer slow down; rollers and bouncers freeze. Firing again while it
  is active restarts the 7 s. A blue tint (0.3, 0.3, 1.0 at 20 %) covers the screen while active; a blue flash
  of 1 s marks the start and one of 300 ms the end.
- **Space Fold**: ends an active hazard zone immediately; zones do not exist yet, so it is just used up.
- Pickups flash in the bonus colour like shield pickups.
- Determinism: with the bonuses disabled the generated spots are exactly as before; with them enabled the same
  seed gives the same spots.
- The existing rules and tests keep working. The RG351P benchmark is skipped for this intent at the user's
  request.
- The user reviews it (screenshots).

## Out of scope
- Hazard zones, upgrades (the Recharger, torpedo and Phase Shift), the "keep going" continue (it fires a
  Quake), achievements, vibration and sound.
- Touch buttons beyond "tap anywhere".

## Open questions
- None.
