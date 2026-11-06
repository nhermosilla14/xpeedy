# 0005. GPU tunnel

- Status: Proposed
- Date: 2026-11-06
- Owner: agent, Nicolás Hermosilla P. (on-device run)
- Intents: 0002
- ADRs: 0007
- Depends on: slice 0004

## Scope
The tunnel looks and behaves exactly as before, but it is drawn by a static mesh and a vertex shader
fed with per-segment frames and the current cross-section, so neither scrolling nor morphing rebuilds
a mesh.

## Layers touched
- Model: `TunnelGeometry` exposes the 17-point cross-section; no gameplay changes.
- View: `TunnelView` builds the mesh once, owns a `ShaderMaterial` (`tunnel.gdshader`) and updates
  its uniforms on segment change and on turn changes.
- Foundation: profiling as a headless script under `tests/` (always quits).

## End-to-end test
- All existing unit and end-to-end tests pass unchanged.
- New tests: the mesh is created once over a run that scrolls and morphs; the uniforms match
  `TunnelGeometry` (frames and cross-section) after scrolling and mid-morph; checker parity flips
  every segment.
- Visual check on the desktop: tube, morph, flat ribbon and outside tube look as in slice 0004.
- Desktop profile: tunnel-view cost per tick during morphs is no higher than outside them.
- RG351P: 60 s including at least two shape changes, results recorded here; pass per intent 0002.

## Out of scope
- Moving the camera or gameplay maths to the GPU.
