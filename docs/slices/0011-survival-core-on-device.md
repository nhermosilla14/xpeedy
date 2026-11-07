# 0011. Survival core on the RG351P

- Status: In progress
- Date: 2026-11-06
- Owner: agent, Nicolás Hermosilla P. (on-device run)
- Intents: 0003
- ADRs: 0009, 0010
- Depends on: slice 0010

## Scope
Verify that the complete Survival core holds the frame-rate budget on the RG351P with obstacles, trails,
spots, explosions and the HUD on screen, fix what does not, and close intent 0003.

## Layers touched
- Foundation: a deterministic benchmark mode (a fixed seed and an autopilot that dodges or ploughs
  through) so runs are comparable; packaging of the new shaders.
- Fixes found by the benchmark, recorded in the slice notes (they may need a superseding ADR).

## End-to-end test
- Desktop profile of CPU per tick with obstacles on screen, explosions active and trails changing.
- RG351P: a 60 s run at full density (play past segment 2250, level 15) and a benchmark run; pass per
  intent 0003: every 10 s window averages ≥ 58 fps with a 1 % low ≥ 50 fps. Results recorded here.
- User confirmation that the game is playable and fun enough to continue.

## Out of scope
- New features. Anything found that needs new behaviour becomes a new intent.

## Progress (2026-11-06)
- Added the benchmark tooling: `LaunchOptions` parses `--benchmark`, `--seed`, `--start-segment`,
  `--invulnerable` and the earlier debug options; `--benchmark` = seed 2024, start at segment 2300 (pattern
  level 15) at full speed, 4 shields, the plough autopilot, obstacles the shields can't pay for are
  ignored, and the run restarts itself 1.5 s after a crash. The frame log now also prints the state
  (`segment`, `level`, `obstacles`, `shields`, `score`). On a handheld the launch script passes the
  contents of `ports/xpeedy/args.txt` to the game (carriage returns stripped).
- Found by a test: the deep start counted the whole distance as score; fixed.
- 161 unit tests and 8 end-to-end tests pass, including `tests/e2e_benchmark.gd` (starts deep with the
  fixed seed, flies and smashes for 12 s, log line has the state, level 15 or more).
- Desktop benchmark at 480×320 with `opengl3_es` (70 s): 75–107 fps average and 51–56 fps 1 % low per
  10 s window, at levels 16–21 with 18–33 obstacles in view.
- CPU profile at full density (`tests/profile_tunnel.gd`): median tick 0.11 ms, 99th percentile 1.0 ms,
  slowest ticks about 1.1 ms (a new segment entering with a new pattern: 0.7 ms views, 0.3 ms
  generation); the one-time first tick is 29 ms (initial uploads).
- Pending: the RG351P run with `--benchmark` and a normal session, and the user's confirmation.
