# 0017. Run flow: start sequence, pause and personal best

- Status: Proposed
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0004

## Context
Intent 0004 adds the start lights, a pause button, a Game Over panel with a personal best, and a best-score
label. These need run states and a small amount of persistence. Doc 14 gives the lights' timing; doc 03
says a run starts at 300 ms per segment and accelerates when the lights go out; doc 17 recommends
freezing every timer while paused; doc 09 keeps personal bests per difficulty.

## Decision
- **Run phases**: `SurvivalRun` has a phase, `STARTING` then `RACING`, and the existing `crashed` state
  ends a run. `RunConfig.countdown` turns the start sequence on (off by default so every existing test
  and the benchmark are unchanged; the game turns it on unless `--start-segment` or `--benchmark` is used).
- **STARTING**: lasts 3.8 s of game time. The ship moves at 300 ms per segment with the speed ramp not
  started, no score is counted and the lights run: light *i* (0–2) starts swelling at `1.3 + i` seconds
  and fades over 0.5 s. When the last one has faded the phase becomes `RACING`, the ramp starts from 300
  ms, and a `RunEvent.RACE_STARTED` is emitted. Obstacles and spots exist as usual; the first appear after
  segment 55, well past where the ship is at the end of the countdown (about segment 16).
- **Pause**: `main.gd` simply stops stepping the run and the clock while paused, which freezes every
  timer (decay, explosions, countdown), as doc 17 recommends. The pause action is Escape or P on a
  keyboard, Start on a gamepad, and the pause button. The Pause panel offers "resume game" and
  "restart".
- **Personal best**: `PersonalBest` (in `src/core/`) reads and writes a `ConfigFile` at `user://best.cfg`,
  one integer per mode key (now `survival_standard`). It is updated when a run ends if the score beats
  it. On PortMaster `user://` lives in the port's `conf/` folder (`XDG_DATA_HOME`), so it persists. The
  path is injectable so tests use a temporary file.
- **Game Over**: when a run ends the crash flash plays, then the panel shows the score and the best
  after the update.

## Alternatives considered
- Always counting down, with tests skipping it — every test would need to know about the countdown.
- A pause flag inside the model — the model is already stepped by the caller, so not stepping is the
  simplest correct pause.
- Saving more progress now (credits, upgrades) — belongs to the persistence intent.

## Consequences
- The existing tests keep their behaviour; the new phase has its own tests.
- The personal best is the first thing written to disk, so a corrupt or missing file must be handled
  (treated as no best).
- The menus intent will reuse the pause panel and the best-score label.
