# 0016. Start sequence, pause and Game Over

- Status: Done
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0004
- ADRs: 0016, 0017
- Depends on: slice 0015

## Scope
The three start lights and the 3.8 s countdown at 300 ms per segment; the pause button, key and gamepad
button with a Pause panel (resume game, restart); the Game Over panel with the score, the saved personal best
and "try again", after the crash flash.

## Layers touched
- Model: run phases and the countdown in `SurvivalRun`, `RunEvent.RACE_STARTED`, `PersonalBest` (a
  `ConfigFile`).
- View: the start lights (procedural dotted discs), `ScreenPanel` built on `GlassPanel` for Pause and Game
  Over, mouse and touch on the choices, `main.gd` pausing by not stepping.
- Foundation: `--no-countdown` and the existing tests' setup, input actions `pause`.

## End-to-end test
- Unit tests: the countdown lasts 3.8 s at 300 ms per segment without score or ramp, then racing starts and
  the speed ramps; light timings; the personal best is saved, loaded, only raised, and a corrupt or missing
  file counts as none; with the countdown off everything behaves as before.
- Scene tests: a run starts with the lights, then races; pausing freezes the clock, the shield timer and the
  explosions and resuming continues; a crash shows the flash then the panel with the right score and best;
  "try again" starts a new run.
- Review with the user: side-by-side screenshots of the start sequence, Pause and Game Over.

## Out of scope
- The main menu, mode and difficulty screens, settings, sound.
