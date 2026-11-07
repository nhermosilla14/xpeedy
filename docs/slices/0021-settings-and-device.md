# 0021. Settings and the menus on the RG351P

- Status: In progress
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (on-device run and final review)
- Intents: 0005
- ADRs: 0018, 0019
- Depends on: slice 0020

## Scope
The Settings screen (invert steering on/off, saved), opened from the gear; the package and the
documentation updated; the device check.

## Layers touched
- Core: `Settings`. View: the settings items on `MenuScreen` (value text). App: invert applied at run start.

## End-to-end test
- Unit tests: settings save, load, defaults for missing and corrupt files; toggling changes the steering
  of the next run.
- Scene test: gear → invert on → play: left input steers right.
- RG351P (user): `--benchmark` still holds the bar (the menu is skipped); a play session through the
  menus with the d-pad and A/B.
- Final review with the user.

## Out of scope
- Other settings (sound, music, vibration, sensitivity, calibration).
