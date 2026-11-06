# 02 – Tunnel and world

## Units and cross-section

- The tunnel is built around a **centre line** (the path) with a **radius of 1 world unit**.
- Its cross-section is a regular **16-sided polygon**. Each side is a **lane**, numbered **0–15** around
  the circumference.
- A lane's width is the polygon's side length: 2·sin(π/16) ≈ **0.390 units**.
- The tunnel is sliced along its length into **segments** of the same length (≈ 0.390 units), so each
  lane-by-segment cell is a square **tile**. Tiles are the grid on which every obstacle and pick-up is placed.
- A position on the track is a pair (**segment**, **lane position**). The segment is a real number that
  increases forever. The lane position is a real number in [0, 16): lane *k* covers [*k*, *k*+1).

The visible tunnel is a sliding window of **50 segments** ahead of the camera. As the ship advances,
old segments are dropped behind and new ones are generated in front. Obstacles, spots and zone marks
are generated as their segment enters this 50-segment horizon.

## Track shapes ("parts")

The track is a sequence of **parts**. Each part has one shape:

| Shape | Name in race files | Description |
|---|---|---|
| Inside | `in` | The ship rides on the **inner** surface of the tube. The circumference wraps around: lane 15 is next to lane 0. |
| Flat | `flat` | The tube is unrolled into a flat **ribbon** 16 lanes wide, lying at the bottom of where the tube would be. Lanes 0 and 15 are the **edges**: driving off either edge is a crash. |
| Outside | `out` | The ship rides on the **outer** surface of the tube, upside-down relative to *in*. The circumference wraps around like *in*. |

The angle between adjacent lane faces differs per shape, which matters for rolling obstacles
([04](04-obstacles.md)): 150° inside, 180° flat, 210° outside.

On flat parts, translucent pulsing **edge bands** are drawn along lanes 0 and 15 to show the drop-off.
They fade in over the last 20 segments before a flat part starts and fade out near its end.

### Shape transitions (morphing)

When one part ends and the next has a different shape, the tunnel **morphs** over **30 segments**. The
transition starts at the boundary: every vertex of the ring moves smoothly from its old shape to its
new one. Visually the tube unrolls from (or rolls up into) the ribbon, working outward from the lane
under the ship.

Rules that apply while morphing:

- **Seam crossing** (steering past the lane 15 ↔ lane 0 boundary):
  - not morphing, tube shape (*in* or *out*): always allowed (wraps around);
  - not morphing, flat: never allowed (wall crash);
  - morphing *from flat into a tube*: allowed only when the morph is ≥ 98 % complete;
  - morphing *from a tube into flat*: allowed only while the morph is ≤ 2 % complete;
  - otherwise it is a wall crash.
- Obstacle hit tests do not wrap around the seam while morphing (see [05](05-shields-and-collisions.md)).
- The camera shakes slightly for the whole transition.

### Shape sequence in random tracks

Survival runs, and any race whose `track` is `random`, generate parts as follows:

- The first part is *in* and lasts at least **200** segments.
- Part lengths are multiples of **120** segments.
- To choose the next shape:
  - after *in*: 50 % stay *in* (the current part is extended by another 120 and the choice is
    repeated), 50 % switch to *flat*;
  - after *out*: always *flat*;
  - after *flat*: *in* or *out* with equal chance, but if the previous tube part was *out*, the next
    tube is *in* 75 % of the time and *out* 25 %.
- *In* and *out* are therefore never adjacent: a flat ribbon always connects them.

Stage races may instead specify an explicit part list ([11](11-stage-mode.md)).

## Path curvature

The centre line is a smooth curve generated on the fly:

- It starts **straight** for about 30 segments.
- It is built from control points spaced **10–20 segment lengths** apart (random each time), joined
  by a smooth cubic curve with continuous direction. Speed along the curve is kept constant per segment.
- At each new control point there is a **50 % chance the path continues straight**. Otherwise the
  direction turns by a random yaw and pitch, each up to 60°–90° (itself random).
- A candidate turn is accepted only if the total bend is **more than 10°** and **less than the
  shape's maximum**: **30°** on flat parts, **50°** in tube parts. After 6 rejected attempts the path
  continues straight.
- The tunnel's "up" direction is carried along the curve with the smallest possible rotation, so the
  tunnel never twists or rolls by itself. Any roll the player sees comes from steering
  ([03](03-movement-and-controls.md)).

The curvature is cosmetic: it does not push the ship sideways. Only the Gravity Well zone does that.

## Start position

A run starts with the ship 3.5 segments into the track and centred on **lane 7** (lane position 7.5).
No obstacles are generated in the first ~25–55 segments (the value depends on the mode).
