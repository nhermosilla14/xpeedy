# 0019. Menu framework, main and difficulty screens

- Status: Done
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0005
- ADRs: 0018, 0019
- Depends on: slice 0018

## Scope
`MenuScreen`, `MenuBackdrop` and `MenuController`; the main menu (play, quit, gear) and the difficulty menu
with badges; the game starts in the menu for a plain run and "play → difficulty" starts a run; `--no-menu`
and `--screen` options.

## Layers touched
- View: the three new controls and their nodes in `main.tscn`.
- App: `main.gd` menu state (3D and HUD hidden while in the menu), start-in-menu rule, tests set it off.
- Foundation: launch options.

## End-to-end test
- Unit tests: selection wraps, the gear is last in the order, activation by index, quit hidden on mobile
  (injectable), the launch options and the start-in-menu rule.
- Scene test: a plain launch shows the main menu with no run; navigating play → standard starts a run with
  the countdown; back returns one level.
- Screenshots (`--screen=main`, `--screen=difficulty`, 480×320 and 960×540): readable, items left-aligned,
  badges drawn.
- Review with the user: screenshots of the menus.

## Out of scope
- Run menus (slice 0020), settings (slice 0021).

## Results
- Menus, backdrop and controller as in ADR 0018; screenshots in `build/look/m-*.png` (not in git). The
  scene test `tests/e2e_menus.gd` covers the whole flow, slices 0019 and 0020 together.
