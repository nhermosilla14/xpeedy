# Documentation index

- [Vision](vision.md) — goals, non-goals, constraints.
- [Architecture](architecture.md) — current high-level design.

## Reference
- [SpeedX 3D mechanics reference](reference/speedx3d/README.md) — behavioural spec of the original
  game; the only source of truth for gameplay (clean-room).

## Intents
| # | Title | Status |
|---|---|---|
| 0001 | [Tunnel prototype](intent/0001-tunnel-prototype.md) | Done |
| 0002 | [Smooth frame pacing on the RG351P](intent/0002-smooth-frame-pacing.md) | Done |
| 0003 | [Survival core: obstacles, shields and score](intent/0003-survival-core.md) | Done |
| 0004 | [Look and interface close to the original](intent/0004-original-look.md) | Accepted |

## Slices
| # | Title | Status |
|---|---|---|
| 0001 | [Walking skeleton](slices/0001-walking-skeleton.md) | Done |
| 0002 | [RG351P spike](slices/0002-rg351p-spike.md) | Done |
| 0003 | [Curving path](slices/0003-curving-path.md) | Done |
| 0004 | [Shapes and morphs](slices/0004-shapes-and-morphs.md) | Done |
| 0005 | [GPU tunnel](slices/0005-gpu-tunnel.md) | Done |
| 0006 | [Obstacles and crashes](slices/0006-obstacles-and-crashes.md) | Done |
| 0007 | [Warning trails](slices/0007-warning-trails.md) | Done |
| 0008 | [Shield spots, shields and the HUD](slices/0008-shields-spots-hud.md) | Done |
| 0009 | [Smashing obstacles](slices/0009-smashing-obstacles.md) | Done |
| 0010 | [Pattern catalogue and difficulty progression](slices/0010-pattern-catalogue.md) | Done |
| 0011 | [Survival core on the RG351P](slices/0011-survival-core-on-device.md) | Done |
| 0012 | [Tunnel look: violet surface, bands and rails](slices/0012-tunnel-look.md) | Proposed |
| 0013 | [Trails and shield spots look](slices/0013-trails-and-spots-look.md) | Proposed |
| 0014 | [Obstacles and fragments look](slices/0014-obstacles-look.md) | Proposed |
| 0015 | [Typeface and HUD](slices/0015-font-and-hud.md) | Proposed |
| 0016 | [Start sequence, pause and Game Over](slices/0016-start-pause-game-over.md) | Proposed |
| 0017 | [The original look on the RG351P](slices/0017-original-look-on-device.md) | Proposed |

## ADRs
| # | Title | Status |
|---|---|---|
| 0001 | [Record architecture decisions](adr/0001-record-architecture-decisions.md) | Accepted |
| 0002 | [Godot 4.4 with the Compatibility renderer](adr/0002-godot-4-4-compatibility-renderer.md) | Accepted |
| 0003 | [GDScript only](adr/0003-gdscript-only.md) | Accepted |
| 0004 | [Deterministic, fixed-step gameplay model](adr/superseded/0004-deterministic-gameplay-model.md) | Superseded by 0005 |
| 0005 | [Per-subsystem random streams](adr/0005-per-subsystem-random-streams.md) | Accepted |
| 0006 | [Tunnel shapes as a hinged face chain](adr/0006-tunnel-shapes-face-chain.md) | Accepted |
| 0007 | [Tunnel geometry evaluated on the GPU](adr/0007-gpu-tunnel-geometry.md) | Accepted |
| 0008 | [Survival run model](adr/0008-survival-run-model.md) | Accepted |
| 0009 | [Obstacles, trails and spots on the GPU](adr/superseded/0009-gpu-obstacles-trails-spots.md) | Superseded by 0011 |
| 0010 | [HUD, flashes and explosions](adr/superseded/0010-hud-flashes-explosions.md) | Superseded by 0012 |
| 0011 | [Obstacles, trails and spots on the GPU, RGBA8 trail texture](adr/0011-gpu-obstacles-trails-spots-rgba8.md) | Accepted |
| 0012 | [HUD with a common shield bar, flashes and explosions](adr/0012-hud-common-shield-bar.md) | Accepted |
| 0013 | [Obstacle pattern generation rules](adr/0013-obstacle-pattern-rules.md) | Accepted |
| 0014 | [Visual reference](adr/0014-visual-reference.md) | Accepted |
| 0015 | [The original's world look, drawn procedurally](adr/0015-procedural-world-look.md) | Proposed |
| 0016 | [Interface style: typeface, HUD and screen panels](adr/0016-interface-style.md) | Proposed |
| 0017 | [Run flow: start sequence, pause and personal best](adr/0017-run-flow-and-personal-best.md) | Proposed |
