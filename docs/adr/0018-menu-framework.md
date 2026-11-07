# 0018. Menu framework and app flow

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (delegated to the agent), agent
- Intent: 0005

## Context
Intent 0005 adds a main menu, a difficulty menu, settings and in-run menus. Until now `main.gd` starts a run
on load. The menus must work without a pointer (RG351P), scale like the HUD (ADR 0016) and not touch the
rules or the tests that drive `main.tscn` directly.

## Decision
- **One generic `MenuScreen` control** (`src/view/menu_screen.gd`): a list of items (text, optional badge
  with a colour and a triangle count, optional value text), a selection index, an optional back arrow
  (bottom-left) and an optional gear (bottom-right). It is drawn in the interface typeface (ADR 0016): items
  light grey `#C4BFC4`, the selected or pressed item amber `#D8A64A`, item height about 11 % of the screen
  height, left-aligned at the top-left. It emits `activated(index)`, `gear_pressed` and `back_pressed`. The
  gear is the last element in the navigation order, so a gamepad can reach it. Pointer: highlight while
  pressed, activate on release (doc 14).
- **`MenuBackdrop`** (`src/view/menu_backdrop.gd`): a control that fills the screen with `#190713` and draws
  four to six dark cubes with neon edges, rotating and drifting slowly, projected in 2D by a few lines of
  maths. No assets, no 3D scene.
- **`MenuController`** (`src/view/menu_controller.gd`, a node under the HUD layer) owns the screens and a
  stack of them (main, difficulty, settings), reads the navigation actions (`ui_up`, `ui_down`,
  `ui_accept`, `ui_cancel`) and emits `play_requested(difficulty_key)` and `quit_requested`. It only knows
  names and keys, not the game.
- **`main.gd` has two states**: in the menu (3D nodes and the HUD hidden, the backdrop and the controller
  shown; no run exists) and in a run (as now). `start_run` leaves the menu; the pause and Game Over panels
  offer "main menu", which discards the run and returns to the main screen.
- **Debug options and tests skip the menu**: the menu shows only for a plain run (the same test as the
  start sequence, `LaunchOptions.is_plain_run()`) unless `--no-menu` is given; tests set
  `Main.start_in_menu = false`. A new `--screen=main|difficulty|settings` option opens that screen first
  (for screenshots).
- **Navigation inputs**: the stock `ui_*` actions already map arrows, d-pad, Enter, Space, A and B/Esc.
  While a panel or menu is open it consumes them; during a run only `pause` and `restart` apply. After a
  crash the panel takes `ui_accept`, `ui_up`, `ui_down` and `ui_cancel` (back → main menu); until the panel
  shows (the 1 s flash) `restart` still restarts at once.
- **Quit**: `get_tree().quit()`; the item is hidden when `OS.has_feature("mobile")` or `"web"`.

## Alternatives considered
- Godot `Button` and `Theme` controls — focus navigation works, but the original's look (large bare text,
  amber highlight, release-to-activate) needs custom drawing anyway, and a theme per screen adds weight.
- A separate menu scene with a scene change — loses the loaded shaders and complicates the tests that
  instantiate `main.tscn`.
- A 3D tunnel backdrop (as the original has) — costs a second view and frame time on the handhelds; the
  drifting cubes carry the look.

## Consequences
- Later menus (mode select, upgrades, help) are new item lists on the same control.
- The tests keep instantiating `main.tscn` with the menu off.
- The menu is its own state, so menu frame-rate cost is negligible (a few polygons).
