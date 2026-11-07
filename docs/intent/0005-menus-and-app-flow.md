# 0005. Menus and app flow

- Status: Done
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0018, 0019

## Goal
Xpeedy opens on a main menu like the original's and the player can go from it to a run and back without
restarting the program: main menu → difficulty → run → pause or Game Over → main menu. The five Survival
difficulties exist, each with its own personal best. Everything works with a keyboard, a gamepad (the
RG351P has no pointer) and mouse or touch. Menus follow `docs/reference/speedx3d/14-ui-hud-and-menus.md`.

The user asked for this intent to be carried out without interaction (2026-11-07); the agent accepted the
intent, the ADRs and the slices on their behalf, and the user reviews the result afterwards.

## Acceptance criteria
- **Main menu**: starts the game (unless a debug option starts a run directly). A near-black maroon
  backdrop with a few dark cubes with neon edges drifting slowly; a left-aligned stack of very large
  lowercase items in the interface typeface: "play", then "quit" (hidden on Android and the web); a gear
  icon at the bottom-right opens Settings. Items that do not exist yet (upgrades, help, credits, stage and
  multiplayer modes) are not shown.
- **Difficulty menu** ("play" opens it directly, as there is no other mode yet): casual, easy, standard,
  extreme, pure, each with a round colour badge of 1 to 5 dark triangles (cyan, green, amber, red, blue),
  and a back arrow at the bottom-left. Choosing one starts a run of that difficulty.
- **Difficulties** (doc 10): target speed 133, 100, 80, 67 and 50 ms per segment; Pure has cubes and
  beams only (no spikes). Zones, bonuses, rollers and bouncers come with their own intents. Standard is
  exactly today's run.
- **Personal bests** are kept per difficulty and shown on the Game Over panel and the best-score label of
  that difficulty.
- **Run menus**: Pause offers "resume game", "restart" and "main menu"; Game Over offers "new game" and
  "main menu". Back (Esc, the gamepad's B) in menus goes up one level; after a crash it returns to the main
  menu.
- **Settings**: invert steering on/off, saved on the device and applied to the next run (doc 16). Sound,
  music, vibration, calibration and sensitivity arrive with their features.
- **Navigation**: up/down (keyboard arrows, d-pad) move the amber highlight, accept (Enter, Space, A)
  activates, back goes back; with a pointer an item highlights while pressed and activates on release.
- Everything is readable at 480×320 and scales with the screen height.
- The existing rules, tests and benchmark keep working; debug options that start a run skip the menu. On
  the RG351P, `--benchmark` still holds the intent 0003 frame-rate bar.
- The user reviews the menus (screenshots, and on the device).

## Out of scope
- Mode select, Stage mode, multiplayer, upgrades and the shop, credits, help pages, "keep going?" and
  other dialogs, the first-launch warning, achievements and sign-in.
- Fades between screens, sound and music, tilt calibration, the Android build.
- Custom difficulty.

## Open questions
- None; the observed menus are enough. Anything unobserved is refined in the review.
