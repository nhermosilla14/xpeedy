# 0005. GPU tunnel

- Status: In progress
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

## Results so far (2026-11-06)
- All unit tests (47) and end-to-end tests (3) pass, including `tests/e2e_gpu_tunnel.gd`: through the
  real scene the mesh is built once; over 301 ticks (63 window scrolls, 144 inside a morph) the frames,
  cross-section and checker parity uploaded to the shader match the model.
- Desktop visual check (real GPU): tube, curves, morph, flat ribbon and rolling back up look as before.
- Desktop CPU per tick (`tests/profile_tunnel.gd`, 40 s): tunnel view 0.12 ms in every state
  (was 0.54 ms normally and 2.2 ms while morphing); mesh builds: 1.
- Desktop, 480×320 with `opengl3_es`: 101–112 fps average, 58–72 fps 1 % low.

## RG351P result (2026-11-06)
- Anbernic RG351P, AmberELEC, PortMaster 2026.06.23, `godot_4.4.1` + Weston, 480×320, ~58 s run, seed 2935391032.
- Shape changes in the run (replayed from the seed): in→flat ≈ 19 s, flat→out ≈ 28 s, out→flat ≈ 38 s,
  flat→out ≈ 48 s. That is four morphs and an outside-tube part, so the criterion of at least two is met.

  | Window | Avg fps | 1 % low |
  |---|---|---|
  | 0–10 s | 58.5 | 57.3 |
  | 10–20 s | 60.0 | 60.0 |
  | 20–30 s | 60.0 | 60.0 |
  | 30–40 s | 60.0 | 60.0 |
  | 40–50 s | 60.0 | 60.0 |

  (Before this slice: 52–59 avg, 27–34 1 % low.)
- No shader errors in the log; the Mali-G31 accepts the uniform arrays, so the data-texture fallback in
  ADR 0007 is not needed. The outside-tube shape rendered on the device for the first time.
- Pending: the user's confirmation that shape changes no longer hitch (last acceptance criterion of
  intent 0002).
