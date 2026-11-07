# 0026. Button layout setting and handheld navigation

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (reported on the RG351P), agent
- Intent: none (fixes and a setting found on the device)

## Context
On the RG351P the user found three problems: the back arrow of the Settings page cannot be reached with the
gamepad, the left stick does not move like the d-pad, and the face buttons are always in the Nintendo-like
layout. On PortMaster, `gptokeyb` turns some buttons into keys (`xpeedy.gptk`) while Godot also reads the
joypad directly; the `.gptk` file had `a = enter`, no up/down keys for the d-pad or stick.

## Decision
- **Navigation order**: a menu's back arrow and gear are navigation elements after the items (items, back,
  gear), so a gamepad reaches the back arrow with up/down and activates it with confirm. Select (joypad button
  4) also cancels in every layout.
- **Layout setting**: `Settings.layout` is `"nintendo"` (the layout the game always had: confirm on joypad
  button 0, cancel on button 1) or `"xbox"` (swapped). `InputLayout.apply` rewrites the face-button events of
  `ui_accept`, `fire` and `restart` (confirm) and `ui_cancel` (cancel) at start and when the setting changes.
  The Settings page has a `buttons: nintendo|xbox` item, saved in `user://settings.cfg` (`[input] layout`).
- **Handheld mapping**: `xpeedy.gptk` no longer maps `a` to Enter (it would confirm whatever the layout is;
  Godot reads the face buttons itself, as it already does Start), and maps the d-pad and the left stick up and
  down to the Up and Down keys like left and right, so both drive the menus and the pause panel the same way.

## Alternatives considered
- Swapping the labels only — the buttons would still do the same things.
- Detecting the controller type automatically — handhelds report generic mappings, so the player chooses.

## Consequences
- Anything new that uses a face button must be in `InputLayout`'s action lists.
- The `.gptk` change cannot be tested off the device; the user confirms it on the RG351P.
