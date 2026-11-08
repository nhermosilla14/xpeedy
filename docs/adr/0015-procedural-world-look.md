# 0015. The original's world look, drawn procedurally in the shaders

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0004

## Context
Intent 0004 asks for the original's look: a blue-violet banded tunnel with thick soft rails on every lane
boundary, translucent trails with bright edge lines, dark glassy obstacles with neon outlines, a
perforated amber mesh for shield spots (look notes removed, ADR 0034). The RG351P's Mali-G31 is
fill-rate limited (ADR 0002), cannot sample float textures (ADR 0011), and the project must not use any
asset of the original (ADR 0034). The tunnel and obstacles are already placed by shaders (ADR 0007, 0011).

## Decision
- **Everything is procedural.** No new textures and no image assets: patterns are computed in the
  fragment shaders from tile-local coordinates. The only texture stays the RGBA8 trail data (ADR 0011).
- **Tile-local coordinates in the tunnel.** The tunnel vertex shader derives `local = (u, v)` in [0, 1]² for
  every tile from the vertex's corner and the tile's index (both are already in the mesh) and passes it to
  the fragment shader, together with the per-tile data it already computes (trail, spot, band position).
  Per-tile colour work moves from the vertex shader to the fragment shader.
- **Surface**: a base blue-violet (about `#4A4694`) with a soft wide band along the track: the brightness
  alternates every few segments (period in a constant, starting at 6 segments) with smooth steps, so rings are
  visible but no tile edge is. Fog stays the built-in exponential fog in the dark maroon of the void.
- **Rails**: a bright lavender-white (about `#C9C3D1`) soft strip centred on every lane boundary:
  intensity from the distance to the nearest boundary, a solid core of about 0.07 lane widths, fading out by
  about 0.18. The rail colour is mixed over the surface and then fogged with the distance.
- **Trails**: the fill is the obstacle colour darkened (about 30 %) mixed over the surface by the doc 04
  fade; bright edge lines of the full colour, about 0.07 lane widths wide, sit on the tile's lane borders.
  The red-orange highlight keeps its rules. The rails still show through.
- **Shield spots**: a hexagonal mesh of dots (6 columns, 6 rows per tile, dot radius about a third of the
  cell) in amber on near-black.
- **Obstacles**: no lighting. The body is the obstacle colour at about 16 % brightness with a fixed
  per-face variation, and the edges are lines of the full colour. Boxes (cubes, beams) compute edges in
  prism space, from the interpolated `(u, v, height)` coordinates they already carry, so the line width is
  the same on every face and on long beams; the spike mesh carries barycentric coordinates in `UV2`
  for its edges. No alpha blending: bodies are opaque.
- **Fragments** of an explosion use the same dark body and bright edge, from their quad's UV.
- **Shared constants** (palette, rail and edge widths) live in one shader include,
  `src/view/look.gdshaderinc`, used by the tunnel, obstacle and fragment shaders.
- **Review tooling**: a debug launch option `--screenshot=PATH[,SECONDS]` saves the viewport to a PNG after
  the given time and quits, so Xpeedy can be captured in a given state (seed, start segment) and compared
  side by side with the reference.
- **Budget**: the fragment shaders have no loops and no texture fetches; the RG351P benchmark has to hold
  intent 0003's bar. If it does not, the fallbacks are, in order: hard-edged rails, no band smoothing,
  fewer spot dots.

## Alternatives considered
- Textures for rails, bands and the dot mesh — would need image assets and mipmaps, and cost memory
  bandwidth on the handhelds.
- A post-process glow — too expensive on the Mali-G31.
- Real transparency for obstacles and trails — sorting and overdraw problems, and no gain for the look.

## Consequences
- The look is tuned by editing a few constants, and the same shaders serve every platform.
- Per-fragment work grows from a copy to a few dozen operations; this has to be measured on the device.
- Slices 0012–0014 each end with a side-by-side screenshot review, since "close to the original" is judged
  by eye.
