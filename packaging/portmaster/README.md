## Notes

Xpeedy is a free, GPL-3.0 clone of the discontinued tunnel racer SpeedX 3D, by Nicolás Hermosilla P.
Source: TODO (GitHub URL once published).

This is an early prototype: a tunnel you can fly through and steer around. It switches between tube,
flat and outside shapes; driving off a flat edge crashes. Frame-rate reports are
written to `ports/xpeedy/log.txt` every 10 seconds (`[bench]` lines).

## Controls

| Button | Action |
|--|--|
| D-Pad Left / Left stick | Steer left |
| D-Pad Right / Right stick | Steer right |
| A | Restart after a crash |
| Select + Start | Quit |

## Benchmarks and debugging

Create a text file `ports/xpeedy/args.txt` with options on one line and launch the port; they are
passed to the game. For a comparable frame-rate run use `--benchmark` (fixed seed, starts deep at pattern
level 15 with 4 shields, an autopilot flies and restarts itself after a crash). The game logs a line
every 10 seconds to `ports/xpeedy/log.txt`, for example
`[bench] t=10s avg=60.0 fps low1%=60.0 fps frames=601 | segment=2449 level=16 obstacles=27 shields=0 score=850`.
To play at depth yourself use `--start-segment=2300 --shields=4`. Delete the file to play normally.
