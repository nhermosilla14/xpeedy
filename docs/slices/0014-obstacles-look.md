# 0014. Obstacles and fragments look

- Status: Done
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0004
- ADRs: 0015
- Depends on: slice 0013

## Scope
Cubes, beams and spikes become dark bodies with bright neon edge lines and no lighting; the fragments of an
explosion get the same treatment.

## Layers touched
- View: `obstacle.gdshader` (prism-space edges for boxes, barycentric edges for spikes), the spike mesh gets
  `UV2` barycentric coordinates, `fragments.gdshader` quad edges.

## End-to-end test
- All existing tests pass (instance data and uniforms are unchanged).
- On a real GPU: screenshots of a cube, a beam crossing a tube and a spike (fixed seed and start segment)
  show a dark body and bright edges in the obstacle's colour, equal edge width on a beam's long and short
  faces; a screenshot during a smash shows edge-lit fragments.
- Review with the user: side-by-side screenshots of each obstacle type and a smash.

## Out of scope
- The HUD, the start sequence, the Game Over panel.
