# 01 – Overview

## Concept

SpeedX 3D is a first-person, endless-runner style racing game. The player flies a (never shown)
ship at high speed through a procedurally curving tunnel made of 16 lanes. The ship always moves
forward on its own; the player only steers **sideways**, around the tunnel's circumference, by
tilting the device. The goal is to survive as long as possible (or to reach the finish line in stage
races) while avoiding obstacles.

Core loop:

1. The ship moves forward automatically and keeps accelerating up to the mode's top speed.
2. Obstacles appear ahead. Each obstacle is announced by a coloured **trail** painted on its lane.
3. The player steers around them. Hitting an obstacle without enough **shields** ends the run.
4. Orange **shield spots** on the track add shield units. Shield units decay over time, and they are spent
   to smash through obstacles, which also earns bonus points.
5. Coloured **bonus spots** grant a single held power-up (Quake, Time Dilation, Space Fold), which
   the player triggers by tapping the screen.
6. Full-width **zone marks** trigger a 7-second **hazard zone** that changes visuals or physics.
7. The tunnel periodically **changes shape** between riding *inside* a tube, a *flat* ribbon and
   riding *outside* a tube.
8. Distance travelled is the main source of points.

## Game modes

| Mode | Summary | Ends when |
|---|---|---|
| **Survival** | Endless procedural run at one of five fixed difficulties, or a custom one. Difficulty increases with distance. | The player crashes |
| **Single / Stages** | 4 stages × 12 hand-tuned races, each defined by a race description file. Races have a finish line and are played in order. | The player crashes or reaches the finish |
| **Multiplayer (Challenges)** | Asynchronous: two players play the same seeded Survival run and compare scores, betting credits. Required an online service that no longer exists. | The player crashes |

Details: [10 Survival](10-survival-mode.md), [11 Stages](11-stage-mode.md), [12 Challenges](12-multiplayer-challenges.md).

## Session flow

```
App start ─► (first launch only: photosensitivity warning) ─► Main menu
Main menu ─► New game ─► Mode select ─► Survival ─► Difficulty select ─► Run
                                      ├► Single ──► Stage select ─────► Run (next race of that stage)
                                      └► Multiplayer ─► Challenge actions
Run: start sequence (3 lights, sensor calibration) ─► racing ─► crash or finish ─► end-of-run menu
```

A run's internal states are: *starting* (countdown), *in progress*, *paused*, *crashed* (resolving the
"keep going" offer), and *game over* (end-of-run menu shown). See [14](14-ui-hud-and-menus.md).

## Glossary

| Term | Meaning |
|---|---|
| Segment | One ring-step of tunnel length; the unit of distance |
| Lane | One of 16 strips across the tunnel's width |
| Part | A stretch of track with one shape: *in* (inside a tube), *flat*, or *out* (outside a tube) |
| Morph | The 30-segment transition between two parts of different shape |
| Trail | Coloured strip painted on an obstacle's lane ahead of it, warning the player |
| Spot | A pick-up area on the track: shield, bonus, zone mark, or finish line |
| Construct | A pattern of one or more obstacles placed together |
| Shield unit | One "hit point"; spent to smash obstacles and lost over time |
| Zone | A timed hazard (Blackout, Gravity Well, Hue Shift, Dark Nebula, Plasma Cloud) |
| TPS | Time per segment in milliseconds: the speed measure (lower is faster) |
| Credits (Cr) | Soft currency used for upgrades and continues |
