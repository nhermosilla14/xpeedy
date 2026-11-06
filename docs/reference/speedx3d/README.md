# SpeedX 3D – game mechanics reference

Behavioural documentation of **SpeedX 3D 1.96** (Gamelion / ByteStorm, 2013–2015), written so the
game can be reimplemented in any language or engine. It describes *what the game does*: rules, tuning
values, timings, formulas expressed in words, and edge cases. It deliberately avoids describing how
the original code is structured.

Everything here was derived from studying the behaviour of the original Android build. When the
in-game help text disagrees with what the game actually does, these documents follow the actual
behaviour and point out the difference.

## Documents

| # | Topic | Contents |
|---|---|---|
| 01 | [Overview](01-overview.md) | Concept, game modes, session flow, glossary |
| 02 | [Tunnel and world](02-tunnel-and-world.md) | Segments, lanes, the three track shapes, shape transitions, path curvature |
| 03 | [Movement, speed and controls](03-movement-and-controls.md) | Forward speed and acceleration, steering, calibration, camera |
| 04 | [Obstacles](04-obstacles.md) | Obstacle types, hit boxes, trails, moving obstacles, constructs |
| 05 | [Shields and collisions](05-shields-and-collisions.md) | Shield units, decay, smashing obstacles, crashes, wall crashes |
| 06 | [Bonuses](06-bonuses.md) | Pick-up spots, Quake, Time Dilation, Space Fold |
| 07 | [Hazard zones](07-hazard-zones.md) | Blackout, Gravity Well, Hue Shift, Dark Nebula, Plasma Cloud |
| 08 | [Upgrades](08-upgrades.md) | The seven upgrades, unlock schedule, prices, in-run activation |
| 09 | [Scoring and records](09-scoring-and-records.md) | Points, personal bests, achievements |
| 10 | [Survival mode](10-survival-mode.md) | Difficulties, the custom difficulty, procedural generation rules |
| 11 | [Stage mode](11-stage-mode.md) | Stages and races, progression, race file format, race catalogue |
| 12 | [Multiplayer challenges](12-multiplayer-challenges.md) | Asynchronous wager challenges (online service, now defunct) |
| 13 | [Economy](13-economy.md) | Credits, where they came from, what they buy, "keep going" |
| 14 | [UI, HUD and menus](14-ui-hud-and-menus.md) | Menu tree, in-game HUD, pause and end-of-run menus, start sequence |
| 15 | [Feedback: visuals, audio, haptics](15-feedback-visuals-audio.md) | Screen flashes, colours, sounds, music, vibration |
| 16 | [Persistence and settings](16-persistence-and-settings.md) | What is saved, settings and their effects |
| 17 | [Quirks and reimplementation notes](17-quirks-and-notes.md) | Original bugs, frame-rate dependencies, recommended fixes |

## Conventions used in these documents

- **Segment**: the unit of distance along the tunnel. Almost every distance and frequency is expressed
  in segments. See [02](02-tunnel-and-world.md).
- **Lane**: one of the 16 strips that make up the tunnel's cross-section, numbered 0–15.
- **Time per segment (TPS)**: how many milliseconds the ship takes to travel one segment. A *lower*
  value means *faster* movement. All speeds are given this way because the original game is tuned in it.
- **Game time** vs **real time**: the game clock can be slowed down (see Time Dilation in
  [06](06-bonuses.md)). Unless stated otherwise, durations are in game time.
- "Random *a*–*b*" means a uniformly random integer from *a* up to, but not including, *b*, unless stated otherwise.
- Probabilities are given as fractions; "1 in 8" means 12.5 %.
