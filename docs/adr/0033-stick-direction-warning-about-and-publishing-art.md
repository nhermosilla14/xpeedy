# 0033. Stick direction setting, the warning on every launch, the About page and the PortMaster art

- Replaces: 0030-warning-and-credits-screens
- Status: Accepted
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (reported and requested), agent
- Intent: none (bug fixes and publishing material)

## Context
After ADR 0027 the RG351P's left stick works, but steers the wrong way (left goes right) while the d-pad is
right: the device reports its stick the other way round. The author wants the photosensitivity warning on every
launch, not once, an About section that holds the credits and shows a proper version, and a cover and a video
for publishing the port on PortMaster.

## Decision
- **Stick direction**: `SteerInput` reads the keys and the d-pad through the `steer_left` and `steer_right`
  actions (the stick's axis events are no longer part of them) and the left stick's horizontal axis directly,
  with the 0.2 dead zone, and reverses only the stick when `Settings.stick_flipped` is on. The setting is
  `stick: normal|flipped` on the Settings page and in `user://settings.cfg` (`[input] stick`); when it is not
  saved it defaults to flipped on Linux arm64 (the handhelds) and to normal elsewhere. Menus keep the stock
  `ui_*` actions.
- **Warning**: the page of ADR 0030 shows on every launch (where the menu opens, but not for `--screen` and tests);
  "i understand" only continues. The `warning_seen` flag is gone.
- **About**: the main menu's "credits" item becomes "about": page 1 shows "xpeedy", "version X.Y.Z" (the
  project setting `application/config/version`, now 0.9.0: the game is complete apart from Android, which was
  dropped), "a clone of speedx 3d" and "free software, gpl-3.0"; page 2 shows the credits of ADR 0030 and the
  font. It pages like the help topics ("next", then "back").
- **PortMaster art**: `tools/make-portmaster-art.sh` and `tools/make_cover.py` produce `cover.png` and
  `screenshot.png` (640×480) and `preview.mp4` (12 s of an autopilot run with the music, 640×480, 30 fps,
  H.264 and AAC, recorded with Godot's movie writer) into `packaging/portmaster/`, committed. The package
  script also assembles `build/portmaster/submission/`, the layout of a PortMaster pull request. The PortMaster
  README is rewritten for the current game.

## Alternatives considered
- Detecting the stick's sign from the device — handhelds report generic mappings; a setting with a sensible
  default is simple and fixable by the player.
- Flipping the menu's up/down too — only left/right was reported wrong; kept stock until a report says more.
- Hiding the warning after the first launch — the author wants it every time.

## Consequences
- A device whose stick is already right can switch the setting back.
- The version lives in one place; the About page and the packaging read it.
- The cover and the video have to be regenerated when the look changes (one script).
