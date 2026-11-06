# Xpeedy

A free, open-source clone of the discontinued tunnel racer SpeedX 3D: fly through a curving 16-lane
tunnel at high speed and steer around obstacles. It targets desktop, Android and PortMaster
handhelds (down to the Anbernic RG351P). See [docs/vision.md](docs/vision.md).

> Status: the tunnel prototype is done ([intent 0001](docs/intent/0001-tunnel-prototype.md)) and runs at
> a locked 60 fps on the RG351P ([intent 0002](docs/intent/0002-smooth-frame-pacing.md)). Next: gameplay
> (obstacles, shields, scoring).
> A curving tunnel that switches between tube, flat and outside shapes is playable, on desktop and
> PortMaster handhelds. Drive off a flat edge and you crash.

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
Benchmark lines (`[bench] ... avg=… fps low1%=… fps`) are written to `ports/xpeedy/log.txt` every 10 s.

## Usage
| Action | Keyboard | Gamepad |
|---|---|---|
| Steer left | ← / A | left stick, D-pad left |
| Steer right | → / D | left stick, D-pad right |
| Restart after a crash | R / Enter | A, Start |

Debugging: run the exported game with `-- --ghost` to pass through obstacles and `-- --shields=4` to start
with shields.
On handhelds, A restarts after a crash and Select + Start quits. The frame rate is shown in the top-left corner.

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
