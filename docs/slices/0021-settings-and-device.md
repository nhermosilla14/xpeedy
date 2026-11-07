# 0021. Settings and the menus on the RG351P

- Status: Done
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

## Results so far (2026-11-07)
- Settings, the gear, the settings page and applying invert at run start are done and tested
  (`tests/unit/test_settings.gd`, `tests/e2e_menus.gd`). Debug and benchmark runs ignore the settings.
- Desktop `--benchmark` at 480×320: about 117–120 fps. Package built: `build/portmaster/xpeedy.zip`.
- Pending: the RG351P run (benchmark and a play session through the menus with the d-pad, A and B) and the
  user's final review; then this slice and intent 0005 are closed.

## Device results (2026-11-07, RG351P)
- `--benchmark`, 68 windows over about 680 s: first window 58.5 fps average with a 1 % low of 55.4 fps,
  every later window 59.2–60.0 average; the bar (58 average, 50 low) held. One window shows the menu
  state, because the user went through the pause menu to the main menu and started again during the run.
- The user played through the menus with the d-pad, A and B: "simple but good enough".
