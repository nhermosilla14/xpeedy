# 0027. The analog sticks are left to the game on handhelds

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (reported on the RG351P), agent
- Intent: none (fix found on the device)
- Replaces: the stick part of 0026-input-layout-and-handheld-navigation

## Context
ADR 0026 mapped the left stick to the arrow keys in `xpeedy.gptk` (up and down newly, left and right already).
On the RG351P the user then reported that a small tilt of a stick steers, but a larger or full tilt moves the
ship a little and then stops. A small tilt stays below gptokeyb's threshold and reaches the game as the analog
axis, which works; beyond the threshold gptokeyb takes the stick over and turns it into a key, which does not
reach the game as a held input (the d-pad works because the game reads it as joypad buttons).

## Decision
- `xpeedy.gptk` no longer maps any stick direction (`left_analog_*` unmapped, like the right stick), so the
  game receives both sticks only as analog axes at every tilt. The game already maps the left stick's
  horizontal axis to steering and both axes to menu navigation (the stock `ui_*` actions), with the same
  actions as the d-pad.
- The d-pad mapping of ADR 0026 stays.

## Alternatives considered
- Mapping the stick through Godot only and keeping gptokeyb's keys — the two sources would fight, as seen.
- Raising gptokeyb's stick threshold — not configurable per port in a portable way.

## Consequences
- The fix is in the package's `.gptk` and has to be confirmed on the RG351P.
- If a device's stick still stops at full tilt, the next suspect is the game's axis dead zone (0.2).
