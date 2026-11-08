## Notes

Xpeedy is a free, GPL-3.0 clone of the discontinued tunnel racer SpeedX 3D, developed by Nicolás Hermosilla
(nhermosilla14), with thanks to the great developers at GameLion for the original idea. No asset of the
original is used.

Steer around a curving 16-lane tunnel at high speed, smash or dodge obstacles, collect shields and bonuses, and
survive the hazard zones. Play Survival (five difficulties) or Stage mode (48 races), buy upgrades with the
credits you earn, and read the in-game help for the rules.

**Warning:** this game contains flashes and visual effects that may be triggering for people who are sensitive
to them. It shows this warning every time it starts.

## Controls

| Button | Action |
|--|--|
| D-Pad / Left stick | Steer left and right, move in menus |
| A | Confirm (Fire a held bonus in a run) |
| B | Back (see Settings for the Nintendo or Xbox layout) |
| X / Y / R1 | Shield Recharger / Tachyon Torpedo / Phase Shift |
| Start | Pause, resume |
| Select | Back in menus |
| Select + Start | Quit |

If the left stick steers the wrong way, switch "stick" in Settings (the gear icon on the main menu).

## Settings and saved data

Settings, progress, credits and best scores are saved in `ports/xpeedy/conf/`. Sound, music and vibration can be
switched off in Settings.

## Benchmarks and debugging

Create a text file `ports/xpeedy/args.txt` with options on one line and launch the port; they are
passed to the game. For a comparable frame-rate run use `--benchmark` (fixed seed, starts deep at pattern
level 15 with 4 shields, an autopilot flies and restarts itself after a crash). The game logs a line
every 10 seconds to `ports/xpeedy/log.txt`, for example
`[bench] t=10s avg=60.0 fps low1%=60.0 fps frames=601 | segment=2449 level=16 obstacles=27 shields=0 score=850`.
To play at depth yourself use `--start-segment=2300 --shields=4`. Delete the file to play normally.

Source: TODO (GitHub URL once published).
