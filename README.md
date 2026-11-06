# Xpeedy

A free, open-source clone of the discontinued tunnel racer SpeedX 3D: fly through a curving 16-lane
tunnel at high speed and steer around obstacles. It targets desktop, Android and PortMaster
handhelds (down to the Anbernic RG351P). See [docs/vision.md](docs/vision.md).

> Status: tunnel prototype in progress ([intent 0001](docs/intent/0001-tunnel-prototype.md)).
> A straight tunnel you can steer around is playable.

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

## Usage
| Action | Keyboard | Gamepad |
|---|---|---|
| Steer left | ← / A | left stick, D-pad left |
| Steer right | → / D | left stick, D-pad right |

The frame rate is shown in the top-left corner.

## Project structure
```
src/                  game code: core/ (helpers), model/ (gameplay state), view/ (drawing), main scene
tests/                unit tests (unit/), end-to-end scene scripts (e2e_*.gd), runner
tools/                godot.sh (containerised Godot), test.sh, export.sh
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
- Test: `tools/test.sh`. Unit tests extend `TestCase` and live in `tests/unit/test_*.gd`; scene-level
  checks are `tests/e2e_*.gd` scripts extending `SceneTree`.
- Export: `tools/export.sh [preset]` (default `Linux`).
- Style: statically typed GDScript, official Godot style guide, tabs.
- Trunk-based on `main`, small focused commits.

## Documentation
See [docs/README.md](docs/README.md).

## License
GPL-3.0-or-later. See [LICENSE](LICENSE).
