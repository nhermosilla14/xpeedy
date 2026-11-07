# 0021. Rollers and bouncers: drawing them

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (go-ahead), agent
- Intent: 0006

## Context
Moving obstacles are drawn by the GPU like the others (ADR 0009, 0015). Rewriting instance buffers every
frame would cost CPU time on the handhelds, and the model's motion is a closed form of the game time
(ADR 0020).

## Decision
- **Same instance layout.** Rollers and bouncers use two more instanced prism meshes (the cube's) in
  `ObstacleView`. `INSTANCE_CUSTOM` stays (lane, absolute segment, code, alive); `code` is the colour index +
  8 × shape (0 IN, 1 FLAT, 2 OUT) + 24 × (1 if direction is +1) + 48 × kind (0 static, 1 roller, 2 bouncer),
  and the fourth value is 0 for hidden and `1 + phase` for shown. Static obstacles keep `code = colour`.
- **Motion in the vertex shader** from two uniforms, `game_time` and `target_tps`, with the formulas of
  `MovingMath` repeated and a comment pointing at it:
  - Bouncer: the vertex is lifted along the tile's normal by `h(t)`.
  - Roller: the cube is rotated about its bottom edge shared with the next lane by `progress × 90°` (a visual
    quarter turn, whatever the step angle, so it lands square), and each vertex that ends beyond the edge is
    placed on the next lane's frame. At rest it sits on its lane.
- **Instance data is written only when obstacles change** (as now); only the two uniforms change per frame,
  set from `main.gd` with the run's game time. They are **global shader uniforms** (`game_time`,
  `target_tps` in `project.godot`, set with `RenderingServer.global_shader_parameter_set`): setting a
  material parameter every frame re-uploads all of the material's uniforms, which cost about 40 % of the
  frame rate in the first attempt.
- **Look**: the shader's body and edge code for cubes is reused unchanged (prism-space edges).
- **Stomp**: `ShipCamera.shake(seconds)`, using the morph shake's amplitude.
- **Explosion** of a smashed moving obstacle starts at its position at that moment.

## Alternatives considered
- Per-frame CPU animation of instance transforms — more CPU work and bandwidth on the handhelds.
- A second shader for moving obstacles — duplicates the placement code.

## Consequences
- The shader and `MovingMath` must be kept in step; a unit test pins the formulas and a screenshot review
  checks the look.
- One more tier of shader maths in the vertex stage (no loops, a few trig calls per vertex).
