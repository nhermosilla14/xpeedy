# 0023. Hazard zones: model and effects

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (go-ahead), agent
- Intent: 0008

## Context
Zones (doc 07) are timed global modifiers started by marks on the track. They change the look of the world
(shaders, fog, camera), the steering and the shield stack. The run model is deterministic and stepped by
game-time `dt`; trails and spots travel to the GPU in the RGBA8 trail texture (ADR 0011, 0022); global shader
uniforms are cheap to change every frame (ADR 0021).

## Decision
- **`Zone`** (`src/model/zone.gd`) — enum `{ NONE, BLACKOUT, GRAVITY_WELL, HUE_SHIFT, DARK_NEBULA,
  PLASMA_CLOUD }`, names, and mark colour pairs. **`ZoneField`** (`src/model/zone_field.gd`) — marks
  `{seg, zone}` generated as segments enter the horizon from its own stream (`seed ^ 0x20E5`): first point and
  gaps `200 + range(0..200) + 3000/TPS + 1`, zone drawn uniformly with up to 10 re-rolls among the enabled
  zones (a mark whose draws all fail is skipped). Emits `mark_added`, painted by `TrailMap` like spots.
- **Texture**: the alpha byte is now `(code) × 25` with codes 1–4 spots, 5–9 zone marks (zone − 1 + 5) and 10 a
  plasma vortex (the previous factor 60 overflowed). The tunnel shader paints marks (two alternating colours
  over all 16 lanes) and vortices (pulsing blue tile).
- **Lifecycle in `SurvivalRun`**: `zone_state` `IDLE / COUNTDOWN / ACTIVE`, `zone` (the pending or active
  zone), `zone_timer`. The ship crossing a mark (segment ≥ mark segment, once) starts `COUNTDOWN` (3 s) if
  idle; at zero `ACTIVE` for 7 s; at zero idle again. All timers decrease by the tick's `dt` (so Time
  Dilation slows them, pause freezes them). Events: `ZONE_WARNING(zone)`, `ZONE_SECOND(n)`, `ZONE_STARTED`,
  `ZONE_ENDED`. `fire()` of Space Fold ends an active zone (`ZONE_ENDED`) and does nothing in other states.
- **Gravity Well**: at start two phases are drawn from the zone stream (`seed ^ 0x6A57`, one draw pair per
  zone start, in order); `gravity(t)` follows doc 07 exactly; `SurvivalRun.step` adds `0.3 × g × fade` to the
  steer value before the track step, fade = 1 except over the last second (linear to 0). `gravity_value()`
  exposes `g` for the camera.
- **Plasma Cloud**: `VortexField` inside the run: while the zone is active vortices are placed ahead of the
  last one by 5–9 segments on a random lane (own stream `seed ^ 0xC10D`), at most 7/6/4/3 alive by target
  TPS; the same sweep as spots decides a touch; a touch removes the vortex, costs one shield (if any), discards
  the held bonus and emits `PLASMA_TOUCHED` (never a crash). Ending the zone clears them. Vortices are painted
  in the trail map like spots (one tile).
- **View**: global shader uniforms `zone` (0–5, only while ACTIVE) and `zone_time`; the tunnel shader
  switches the surface: Blackout dark negative and no trails, Hue Shift per-lane oscillating colours, Dark
  Nebula pulsing brightness; the obstacle shader switches body and edge colours (Hue Shift grey, Dark Nebula
  negative). `ShipCamera.apply_zone` sets the fog density (0.5 normal, 0.3 for Blackout/Hue Shift/Dark Nebula,
  0.4 ± 0.1 at 2 rad/s for Gravity Well), the yaw, the field of view and a light shake for Gravity Well and
  Plasma Cloud. A `ZoneBanner` label shows the warning with the zone name and 3-2-1; the Plasma Cloud glow is a
  pulsing pale blue `ColorRect`; flashes use the existing `ScreenFlash`.
- **`RunConfig.zones`** is an array of enabled zones (empty by default, so older tracks and tests are
  unchanged); `Difficulty` gives all five to every difficulty but Pure, which gets Blackout only.

## Alternatives considered
- Doing the world effects on the CPU per frame — the shaders already compute the surface per tile.
- Particle fountains for plasma — costly on the handhelds and a second system; a pulsing tile carries the
  hazard now.
- Applying gravity in the track — it is an input offset, so it belongs where the steering is combined.

## Consequences
- Each zone's look is one branch in two shaders and one case in the camera, so new zones stay cheap.
- Stage mode will place marks from race files through the same `mark_added` path.
- Phase Shift will need a protection check at the vortex touch.
