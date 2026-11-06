# 0002. Godot 4.4 with the Compatibility renderer

- Status: Proposed
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0001

## Context
Xpeedy must run on desktop, Android and PortMaster handhelds down to the RG351P (RK3326, 4× Cortex-A35,
Mali-G31, 1 GB RAM, 480×320). Research (PortMaster wiki and packaging guide, porter guides):

- PortMaster ships Godot 3 runtimes (FRT, direct framebuffer) and Godot 4 runtimes
  (`godot_4.2.2` … `godot_4.7.1`) that run inside Weston. The wiki calls Godot 3 "the smoother
  target" on weak devices; Godot 4 is heavier and fill-rate hungry.
- Godot 4 on RK3326 is viable for very simple 3D only with vertex shading (4.4+) and aggressive
  optimisation. Known issues: idle/sleep bug from 4.3 (set the main loop process mode to Always),
  `--main-pack` disabled in 4.6 ARM builds.
- The game's scene is tiny (51×17-vertex tunnel mesh, ≤ ~300 simple objects, fog, no lighting).
- Godot 3 is in maintenance mode, and its Android export is falling behind store requirements.

## Decision
- Use **Godot 4.4.x** (matching the PortMaster `godot_4.4.1` runtime) with the **Compatibility**
  renderer on every platform.
- Rendering budget for low-end: unshaded or vertex-shaded materials, no real-time lights or shadows,
  no post-processing, built-in fog only, render at the device's native resolution (480×320 on the RG351P).
- Validate on the RG351P as part of the first target (tunnel prototype). Pass threshold: a steady
  **≥ 30 fps** in the prototype, with headroom.
- If that threshold can't be met, write a superseding ADR moving to Godot 3.6 (FRT).

## Alternatives considered
- Godot 3.6 (FRT) — smoother on RK3326, but an engine in maintenance mode with a weaker Android
  future. Kept as the documented fallback.
- Prototyping in both engines — doubles the early work; deferred unless the spike fails.
- Forward+ / Mobile renderers — too heavy for Mali-G31 and not supported by the handheld runtimes.

## Consequences
- Modern engine and tooling; one codebase for every target.
- Risk on the RG351P until the spike is measured. PortMaster packaging needs Weston and the
  4.3+ process-mode workaround.
- Pin the editor and export templates to the same 4.4.x patch version.
