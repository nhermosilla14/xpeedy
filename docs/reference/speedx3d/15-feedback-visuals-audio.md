# 15 – Feedback: visuals, audio and haptics

## Look and palette

- **Track**: a light, textured tile surface. Its base colour is white, and the obstacle trails tint lanes
  ([04](04-obstacles.md)).
- **Fog**: exponential, dark purple (≈ 0.20, 0.06, 0.15), density 0.5 normally ([07](07-hazard-zones.md)
  for zone variants). Distant geometry fades into it.
- **Background**: a starfield seen through and beyond the tube on flat and outside parts. On inside
  parts the tube hides it.
- **Obstacle colours**: amber `#FBAF02`, green `#38C36D`, lime `#94C137`, teal `#47B4B3`, mauve `#A95795`.
  Obstacles are textured and translucent-edged.
- **Danger highlight**: red-orange (0.94, 0.12, 0.05).
- **Explosions**: smashed obstacles burst into tumbling fragments of their faces that fly towards and
  past the camera, plus particles.
- **Torpedo**: a glowing projectile with a ribbon tail that follows the tunnel surface.
- **Plasma vortices**: blue particle fountains (six shades of blue/violet), about 120 particles per second,
  lifetimes of 1–2 s, rising and accelerating along the surface normal.
- **Stereoscopic 3D** (optional setting): the scene is rendered twice with a small eye offset, using
  red/cyan or green/magenta colour masks for anaglyph glasses.

## Full-screen flashes

A coloured overlay that fades out linearly. "Additive" flashes brighten the scene; "blend" flashes tint it.

| Event | Colour (RGB) | Duration | Mode |
|---|---|---|---|
| Shield picked up | orange (1.0, 0.7, 0.2) at 75 % | 300 ms | additive |
| Obstacle smashed (or hit by torpedo) | pink-white (1.0, 0.5, 0.5) at 75 % | 300 ms | additive |
| Crash / game over | white | 1000 ms | additive |
| First game (fade-in) | black | 1000 ms | blend |
| Zone mark, each countdown second, zone end, Phase Shift warnings | white | 200 ms | additive |
| Quake | warm (1.0, 0.8, 0.5) | 800 ms | additive |
| Time Dilation start | blue (0.3, 0.3, 1.0) | 1000 ms | additive |
| Time Dilation end | blue (0.3, 0.3, 1.0) | 300 ms | blend |
| Plasma touched | light blue (0.6, 0.6, 1.0) | 1000 ms | additive |
| Phase Shift start and end | white | 500 ms | additive |
| Torpedo launch | torpedo colour | 500 ms | additive |
| Race finished | light green (0.7, 1.0, 0.6) | 1000 ms | blend |

Persistent overlays: a blue tint during Time Dilation, and a pulsing pale-blue glow during Plasma Cloud.

## Sound effects

| Sound | Plays on |
|---|---|
| click | Menu item activated |
| alarm2 (beep) | Each start light |
| alarm (start) | Racing begins |
| shieldup | Shield gained (spot or recharger) |
| breakobs | Obstacle smashed or destroyed by a torpedo |
| warning | Zone countdown begins |
| mdcharge | Bonus picked up |
| shockwave | Quake fired |
| power_down | Plasma touched |
| torpedo | Torpedo launched |
| fold, freez | Loaded for Space Fold and Time Dilation (the original rarely or never plays them) |

All effects are mixed at 0.5–1.0 volume and can be muted with the Sound setting.

## Music

A single looping soundtrack plays during menus and races. Its volume is controlled by the Music setting.

## Vibration (haptics)

| Event | Duration |
|---|---|
| Obstacle smashed, torpedo fired, zone countdown begins | 50 ms |
| Shield picked up, plasma touched | 100 ms |
| Recharger used, Phase Shift activated | 150 ms |
| Bonus picked up | 200 ms |
| Quake | 300 ms |
| Crash | 500 ms |

Vibration can be disabled in Settings.
