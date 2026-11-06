# 0006. Tunnel shapes as a hinged face chain with time-based morphs

- Status: Accepted
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0001

## Context
Doc 02 describes three track shapes (inside a tube, flat ribbon, outside a tube) and 30-segment
morphs between them. Doc 17 says a morph changes every vertex of the visible mesh each frame, so the
morph is driven by the ship's progress through the 30-segment transition, not by distance along the
tunnel. Doc 02 also says the tube unrolls "working outward from the lane under the ship".

## Decision
- The cross-section is a chain of 16 equal faces (width 2·sin(π/16)). Each face is turned by a
  **turn angle** τ relative to its neighbour: τ = +22.5° inside, 0° flat, −22.5° outside. With
  τ = 22.5° the chain closes into the radius-1 16-gon.
- The chain is anchored at **lane vertex 8, directly below the centre line**, and grows symmetrically
  to both sides. Flat is a ribbon tangent to the bottom of the tube; outside is the mirror tube
  hanging below it, ridden on its outer surface.
- The **whole visible tunnel has one shape at a time**. While the ship is inside a transition,
  τ = lerp(τ_old, τ_new, progress), with progress = (ship segment − part start) / 30, clamped to [0, 1].
  The mesh is rebuilt every tick while τ changes, and otherwise only on segment changes.
- Seam rules, banking and shake use that same progress value.

## Alternatives considered
- Anchoring the unroll at the lane under the ship (closer to doc 02's wording) — the flat ribbon's
  position would then depend on where the ship was when each morph started, and consecutive morphs
  with different anchors would jump. Can be revisited later if the effect is missed.
- Morphing as a function of distance (each ring its own shape) — contradicts doc 17, and parts of
  different shapes would be visible at once.

## Consequences
- Shapes are deterministic and continuous; one parameter (τ) drives geometry, normals and banking.
- The outside tube's centre is not the path's centre line (it sits 2 apothems below). This doesn't matter
  for gameplay, since all positions are expressed in (segment, lane) and mapped through the chain.
- Per-tick mesh rebuilds during morphs must be benchmarked on the RG351P (slice 0004).
