# Xpeedy

A free, open-source clone of the discontinued tunnel racer SpeedX 3D: fly through a curving 16-lane
tunnel at high speed and steer around obstacles. It targets desktop, Android and PortMaster
handhelds (down to the Anbernic RG351P). See [docs/vision.md](docs/vision.md).

> Status: planning. The first target is a tunnel prototype ([intent 0001](docs/intent/0001-tunnel-prototype.md)).

## Prerequisites
- [Godot 4.4.x](https://godotengine.org/download/archive/) (standard build, not .NET), with the
  matching export templates. TODO: pin the exact patch version in slice 0001.
- For PortMaster testing: a handheld with PortMaster and its `godot_4.4.1` and Weston runtimes.

## Getting started
TODO: added with slice 0001 (Godot project, run and test commands).

## Usage
TODO. Planned controls: arrows / A–D or gamepad left stick / D-pad to steer.

## Project structure
```
docs/                 vision, architecture, intents, slices, ADRs
docs/reference/       behavioural reference of the original game (clean-room spec)
LICENSE               GPL-3.0
```

## Development guidelines
- Work follows the loop in [AGENTS.md](AGENTS.md): intent (`docs/intent/`) → ADRs (`docs/adr/`) →
  vertical slices (`docs/slices/`) → code and test one slice at a time. Copy the `0000-template.md`
  in each folder and use the next number.
- Gameplay behaviour comes only from [docs/reference/speedx3d](docs/reference/speedx3d/README.md).
- Build, test and lint commands: TODO with slice 0001.

## Documentation
See [docs/README.md](docs/README.md).

## License
GPL-3.0-or-later. See [LICENSE](LICENSE).
