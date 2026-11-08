# 0037. PortMaster package: no gptokeyb mapping file, PortMaster layout and names

- Replaces: the gptokeyb mapping parts of 0026 and 0027 (the `xpeedy.gptk` file); the packaging parts of 0033
  (what the zip and the submission folder contain)
- Status: Accepted
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (requested), agent
- Intent: none (PortMaster publishing)

## Context
PortMaster-New's reviewers check the port against its rules: a launch script committed 644 with LF endings, a flat
`licenses/` folder with one `LICENSE.<component>.txt` per component, metadata in the port folder, a `gameinfo.xml`
that matches the files on disk, and no extra files outside the layout. `xpeedy.gptk` mapped nothing useful: its
button values were a literal `\"`, and its arrow-key mappings duplicated the D-pad, which Godot reads itself (the
`ui_*` defaults and the `steer_*` and `pause` joypad bindings in `project.godot`). ADR 0027 showed that a mapping
and Godot's own input can fight over the same action.

## Decision
- No `.gptk` file. `Xpeedy.sh` runs `gptokeyb` without `-c`: it still provides the quit hotkey and process cleanup.
  Godot reads the gamepad: the D-pad, A, B and Start through the UI and steering actions, and the left stick
  through `SteerInput` (ADR 0027).
- `Xpeedy.sh` is committed 644. The packaging script does not change its mode.
- The zip (what a tester installs) holds `Xpeedy.sh` and the `xpeedy/` game folder: `gamedata/`, `licenses/`
  (`LICENSE.xpeedy.txt`, `LICENSE.orbitron.txt`) and `cover.png`. No metadata is inside the game folder.
- `gameinfo.xml` shows the cover as `<image>./xpeedy/cover.png</image>` (the installed path; PortMaster falls back to
  the screenshot without a cover) and has a `<releasedate>`.
- The submission folder (the layout of a pull request) holds `Xpeedy.sh`, `xpeedy/`, `port.json`, `gameinfo.xml`,
  `README.md`, `cover.png` and `screenshot.png`.
- `preview.mp4` is not packaged. `tools/make-portmaster-art.sh` still generates it; PortMaster's layout has no slot
  for a video.
- `port.json` is unchanged: `version` 4, `image` null, `exp` true for now (see the consequences).

## Alternatives considered
- Keeping the mapping file with the key names fixed — it would duplicate Godot's input and risk the double events
  of ADR 0027.
- Packaging the video in the submission — outside PortMaster's layout.
- Setting `exp` to false now — `exp` hides the port from most PortMaster users until experimental ports are enabled.
  It stays true until the port passes testing on every CFW and CPU in the PortMaster checklist.

## Consequences
- The gamepad path changed. D-pad menus and steering, A, B, Start and the stick must be tested on the RG351P before
  the next testing zip is published.
- PortMaster must run the 644 script through bash. The device test confirms it.
- The examples on the packaging page put the screenshot in the game folder, while the layout lists it in the port
  folder. This is checked when the pull request is made.
- `exp` stays true during testing. The port is marked as ready to run only after it passes the PortMaster checklist.
