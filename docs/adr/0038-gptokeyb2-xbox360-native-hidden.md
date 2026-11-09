# 0038. Gamepads go through gptokeyb2 in xbox360 mode; native gamepads are hidden from Godot

- Status: Proposed (prototype on the branch `prototype/gptokeyb2-xbox360`; becomes Accepted after the RG351P test)
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (requested), agent
- Intent: none (controller input on handhelds)
- Replaces: the gamepad parts of 0037-portmaster-no-gptk-and-layout (gptokeyb without a mapping file, native gamepad
  input) and the stick part of 0027-analog-sticks-left-to-the-game (sticks read natively)

## Context
Native gamepad input in Godot reads the controller's raw buttons when SDL has no mapping for it. Reports from
testers on other devices (ROCKNIX on the Retroid Pocket 5, muOS on the Anbernic RGSP, Knulli on the RG Cube XX) show
wrong buttons, buttons that do nothing, and a mapping that changes during play. Two community patches added
gptokeyb keys on top of native input, which doubles inputs. PortMaster's reviewers expect controller input through
gptokeyb or gptokeyb2 (PortMaster-New AGENTS.md).

gptokeyb2's xbox360 mode (`-x`) creates a virtual Xbox 360 controller (vendor 045e, product 028e) through uinput,
forwards the physical buttons and sticks to it as analog axes, and turns off config mode, so no mapping file is used
(`src/main.c`, `src/xbox360.c`). Godot's bindings in `project.godot` already use the Xbox 360 button numbering.
gptokeyb2's `interpose` library only records the last file descriptor it opens; it does not hide devices.

## Decision
- The launch script runs `$GPTOKEYB2 "$godot_executable" -x` instead of gptokeyb or native input.
- Godot must not read the physical gamepads. The script lists their vendor/product ids (every device with a `js`
  handler in `/proc/bus/input/devices`, except the virtual Xbox 360 pad) and passes them as
  `SDL_GAMECONTROLLER_IGNORE_DEVICES` on the `env` line, so `sudo` cannot strip them. Godot 4.4.1 ignores devices
  with those ids (`core/input/input.cpp`).
- The left stick reaches the game as the virtual pad's analog axis, so it stays analog (no key steering, unlike ADR
  0027's key mapping).
- No `.gptk` file. `project.godot` is unchanged.
- The layout setting (ADR 0026) and the stick direction setting (ADR 0033) keep working in Godot, because they act on
  the virtual pad's buttons and axes.

## Alternatives considered
- `libcrusty.so` from the community patch, which blocks `/dev/input` in Godot: a closed binary with no source, and it
  only loads on the Panfrost path (not on ROCKNIX, where Weston is bypassed).
- Binding only the virtual pad in Godot by device id: works in principle but needs custom input handling for every
  action, including the stock `ui_*` menu actions.
- Keeping native input: the wrong-button reports above.

## Consequences
- Testing needed on the RG351P: the buttons match Xbox 360 layout, the stick is analog at full tilt and keeps its
  direction setting, the layout setting still swaps confirm and cancel, Select + Start quits, and the log's
  "Native gamepads hidden" line lists the device (the expected ids are unknown until then).
- Ids are compared as the kernel reports them. If Godot's byte order differs from the `/proc` form, the list is
  ignored and the native pad stays visible; the log line makes that visible.
- A physical pad that is itself an Xbox 360 pad (045e/028e) stays visible to Godot and would double inputs. It is
  excluded from the list on purpose, because the virtual pad has the same ids.
- gptokeyb2 still reads the physical pads through SDL, so a pad that SDL cannot map is forwarded with wrong buttons.
  That is the controller database problem and is handled separately.
