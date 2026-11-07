# 0013. Trails and shield spots look

- Status: In progress
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0004
- ADRs: 0015
- Depends on: slice 0012

## Scope
Trails become translucent bands with a darkened fill and bright edge lines; the red-orange highlight and the
fade keep their rules. Shield spots become an amber dot mesh on near-black.

## Layers touched
- View: `tunnel.gdshader` trail and spot colouring moved to the fragment stage using the tile-local
  coordinates; the trail texture and `TrailMap` stay as they are.

## End-to-end test
- All existing tests pass (the trail map, texture and uniforms are unchanged).
- On a real GPU: a screenshot with a trail ahead (fixed seed and start segment) shows a darkened fill with
  bright edges, the rails still visible through it; a screenshot with a spot ahead shows the dotted mesh;
  automatic pixel checks for both (fill darker than the colour, edge brighter than the fill, dots in the spot
  region).
- Review with the user: side-by-side screenshots (trails at several distances and in the highlight state, a
  spot), confirm or list differences.

## Out of scope
- Obstacles and fragments, the HUD.
