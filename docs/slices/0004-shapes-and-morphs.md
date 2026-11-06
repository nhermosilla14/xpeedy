# 0004. Track shapes, morphs and wall crashes

- Status: Done
- Date: 2026-11-05
- Owner: agent
- Intents: 0001
- ADRs: 0004
- Depends on: slices 0001, 0003

## Scope
The track switches between in, flat and out parts with 30-segment morphs. Flat parts bank the camera,
and driving off a flat edge or crossing the seam mid-morph crashes the run, with a restart key.

## Layers touched
- Model: `PartSequence` (doc 02 random rules), morph progress, seam-crossing rules, crash state,
  turn limit per shape (30° flat).
- View: per-vertex blend between ring shapes, banking (steer × π/25, rate 5/s), shake ±0.015 while
  morphing, crash camera pitch-up, restart.

## End-to-end test
- Headless tests: first part is in and ≥ 200 segments; part lengths are multiples of 120; in and out
  are never adjacent; after out comes flat; after flat with a previous out, in is chosen ~75 % (statistical
  test with a fixed seed); seam crossing allowed/denied at morph 0 %, 2 %, 50 %, 98 %, 100 % in both directions;
  same seed gives the same sequence.
- Running the project: the tube unrolls into a ribbon and rolls back up, the camera banks on flat parts,
  driving off the edge crashes and the restart key starts a new run.
- Re-run the slice 0002 benchmark on the RG351P with morphs active and record the result.

## Out of scope
- Edge bands, starfield, obstacles.

## Results (2026-11-06)
- RG351P, AmberELEC, 480×320, `godot_4.4.1` + Weston: first 10 s (no morph) 58.9 fps avg / 58.7 fps
  1 % low; afterwards 52–59 fps avg, 27–34 fps 1 % low. Passes the ≥ 30 fps threshold (ADR 0002).
- User feedback: steering in tubes felt glitchy because the camera "up" snapped 22.5° at every lane
  boundary; fixed by blending the normal across faces (commit 84ff1b2). Confirmed "much better".
- Remaining: slight hitches on shape changes, caused by rebuilding the mesh on the CPU. Followed up
  by intent 0002.
- Earlier on the device, slice 0003's curving tunnel ran at a locked 60 fps.
