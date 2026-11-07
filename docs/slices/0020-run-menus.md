# 0020. Run menus and back handling

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0005
- ADRs: 0018
- Depends on: slice 0019

## Scope
Pause with "resume game", "restart", "main menu"; Game Over with "new game", "main menu"; gamepad and
keyboard navigation and accept in both; back after a crash returns to the main menu; the run is discarded
when returning to the menu.

## Layers touched
- App: `main.gd` choice handling and input; `ScreenPanel` unchanged apart from the number of choices.

## End-to-end test
- Scene test: pause → "main menu" shows the main screen and no run steps; Game Over → "new game" starts the
  same difficulty; Game Over → back or "main menu" returns to the main screen; before the panel shows,
  restart still restarts; the existing flow test is extended.

## Out of scope
- Settings, fades.
