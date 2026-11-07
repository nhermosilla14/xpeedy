# Xpeedy

A free, open-source clone of the discontinued tunnel racer SpeedX 3D: fly through a curving 16-lane
tunnel at high speed and steer around obstacles. It targets desktop, Android and PortMaster
handhelds (down to the Anbernic RG351P). See [docs/vision.md](docs/vision.md).

> Status: the Survival core is playable on desktop and on the RG351P at a locked 60 fps ([intent 0003](docs/intent/0003-survival-core.md)):
> menus, five difficulties, tunnel, obstacles, trails, shields, smashing, score, with the original's look and interface ([intent 0004](docs/intent/0004-original-look.md)): start lights, pause, Game Over, saved personal best. Rollers and bouncers ([intent 0006](docs/intent/0006-rollers-and-bouncers.md)) are in on every difficulty but Pure. Bonuses (Quake, Time Dilation, Space Fold; [intent 0007](docs/intent/0007-bonuses.md)) are in; fire the one you hold with Enter, Space, A or a tap. The five hazard zones ([intent 0008](docs/intent/0008-hazard-zones.md)) are in. Not yet:
> sound, upgrades, Stage mode, Android.

## Prerequisites
- [Podman](https://podman.io/) 4+. Godot 4.4.1 and its export templates come from the
  `docker.io/barichello/godot-ci:4.4.1` image, pulled on first use. Override it with `GODOT_IMAGE`.
- Optional: a local Godot 4.4.1 editor (standard build, not .NET) to edit scenes.
- For PortMaster testing: a handheld with PortMaster and its `godot_4.4.1` and Weston runtimes.

## Getting started
```sh
git clone <repo-url> Xpeedy && cd Xpeedy
tools/test.sh        # unit + end-to-end tests (headless, in the container)
tools/export.sh      # builds build/linux/xpeedy.x86_64
build/linux/xpeedy.x86_64
```

### PortMaster (handhelds)
```sh
tools/package-portmaster.sh   # builds build/portmaster/xpeedy.zip
```
Install it on the handheld in one of two ways:
- Copy `xpeedy.zip` to PortMaster's `autoinstall/` folder on the SD card and open PortMaster, or
- unzip it into the `ports/` folder (it contains `Xpeedy.sh` and `xpeedy/`).

The port needs the `godot_4.4.1` and `weston_pkg_0.2` runtimes; PortMaster downloads them on first
launch if Wi-Fi is available, otherwise copy the `.squashfs` files into `PortMaster/libs/`.
Benchmark lines (`[bench] ... avg=… fps low1%=… fps`) are written to `ports/xpeedy/log.txt` every 10 s. On a handheld,
put options in `ports/xpeedy/args.txt` (for example `--benchmark`) to pass them to the game.

## Usage
| Action | Keyboard | Gamepad |
|---|---|---|
| Steer left | ← / A | left stick, D-pad left |
| Steer right | → / D | left stick, D-pad right |
| Restart after a crash | R / Enter | A, Start |

Debugging options for the exported game, after `--` on the command line:

| Option | Effect |
|---|---|
| `--ghost` | pass through obstacles |
| `--shields=4` | start the run with 4 shields |
| `--autopilot=plough` | a pilot flies into what it can smash, else towards shield spots |
| `--timescale=0.2` | slow motion |
| `--seed=N` | fixed run seed |
| `--start-segment=2300` | start deep in the run, at full speed |
| `--invulnerable` | obstacles the shields can't pay for are ignored instead of crashing |
| `--benchmark` | fixed seed, deep start, 4 shields, autopilot, invulnerable, restarts itself: a comparable frame-rate run |
| `--fps` | show the frame-rate counter (also on with `--benchmark`) |
| `--difficulty=KEY` | casual, easy, standard (default), extreme or pure; starts a run directly, skipping the menu |
| `--no-menu` | start a run directly instead of opening the menu |
| `--screen=main\|difficulty\|settings` | open the menu on that page (for screenshots) |
| `--no-countdown` | skip the start sequence (debug options that change the run also skip it, and never save a best) |
| `--zone=blackout\|gravity\|hue\|nebula\|plasma` | start with that hazard zone active (for looking at it) |
| `--clean` | no obstacles or shield spots (for looking at the tunnel) |
| `--start-shape=in\|flat\|out` | start inside the first part of that shape |
| `--screenshot=PATH[,SECONDS]` | save the viewport to a PNG after the delay and quit; `tools/look-shots.sh` uses it |

The game opens on the menu: up/down (arrows, d-pad) select, Enter, Space or A confirm, Esc or B go back; with a mouse or touch an item activates when released. "play" opens the five difficulties; the gear opens settings (invert steering). A run starts with three lights (3.8 s). Pause with Esc, P, Start or the pause button; in the pause panel Up/Down select and A or Enter confirms; after a crash R, Enter, Space or A restarts after a crash (the Game Over panel shows the score and the saved personal best). Select + Start quits on handhelds. Use `--fps` to show the frame rate.

## Project structure
```
src/                  game code: core/ (helpers), model/ (gameplay state), view/ (drawing), main scene
tests/                unit tests (unit/), end-to-end scene scripts (e2e_*.gd), runner
tools/                godot.sh (containerised Godot), test.sh, export.sh, package-portmaster.sh
packaging/portmaster/ PortMaster launch script, port.json, gameinfo.xml, gptk mapping
docs/                 vision, architecture, intents, slices, ADRs
docs/reference/       behavioural reference of the original game (clean-room spec)
project.godot         Godot project; export_presets.cfg holds export targets
LICENSE               GPL-3.0
```

## Development guidelines
- Work follows the loop in [AGENTS.md](AGENTS.md): intent (`docs/intent/`) → ADRs (`docs/adr/`) →
  vertical slices (`docs/slices/`) → code and test one slice at a time. Copy the `0000-template.md`
  in each folder and use the next number.
- Gameplay behaviour comes only from [docs/reference/speedx3d](docs/reference/speedx3d/README.md).
- `tools/godot.sh <args>` runs any Godot command in the container with the repo mounted at `/src`.
  The container is killed after `GODOT_TIMEOUT` seconds (default 300), so a script that never quits
  can't hang. Test scripts must always call `quit()`.
- Test: `tools/test.sh`. Unit tests extend `TestCase` and live in `tests/unit/test_*.gd`; scene-level
  checks are `tests/e2e_*.gd` scripts extending `SceneTree`.
- Profile (CPU per tick by shape): `tools/godot.sh --headless --script res://tests/profile_tunnel.gd`.
- Export: `tools/export.sh [preset]` (default `Linux`). PortMaster zip: `tools/package-portmaster.sh`.
- Style: statically typed GDScript, official Godot style guide, tabs.
- Trunk-based on `main`, small focused commits.

## Documentation
See [docs/README.md](docs/README.md).

## License
GPL-3.0-or-later. See [LICENSE](LICENSE).
