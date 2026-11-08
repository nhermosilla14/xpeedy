# 0031. Generated audio, the sound player and haptics

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (instruction to go on), agent
- Intent: 0011

## Context
Doc 15 lists the sound effects, a looping soundtrack and vibration. The project is clean-room and open source:
no audio of the original may be used, and every asset needs a licence we can ship. The handhelds have little
CPU to spare at start-up.

## Decision
- **Assets are generated offline, committed.** `tools/make-audio.py` (Python standard library only,
  deterministic) writes mono 16-bit 22.05 kHz WAV files to `assets/audio/`: thirteen effects (`click`,
  `beep`, `start`, `shieldup`, `breakobs`, `warning`, `charge`, `shockwave`, `powerdown`, `torpedo`,
  `crash`, `finish`, `phase`) and a `music` loop of about 16 s (bass, arpeggio and percussion). They are our own
  work, covered by the project's GPL-3.0. Synthesising at start-up was rejected: it would take seconds on the
  RG351P.
- **`SoundPlayer`** (`src/view/sound_player.gd`, a node of the main scene) loads the streams once, keeps a
  small pool of `AudioStreamPlayer`s for effects and one for the music (loop set at load), and exposes
  `play(name)`, `vibrate(ms)`, `set_options(sound, music, vibration)`, `start_music()`. It records what it
  played in `played` (a list kept for tests) and does nothing when its option is off. Effect volumes are in a
  table between −6 dB and 0 dB.
- **`SoundMap`** (`src/core/sound_map.gd`) is a pure table: `for_event(RunEvent.Kind)` gives `{sound, vibrate_ms}`
  for the run events of doc 15; the menu click and the start lights are triggered by `main.gd` directly.
- **Settings**: `sound`, `music` and `vibration` booleans (default on) in `user://settings.cfg` under `[audio]`
  and `[haptics]`; the Settings page lists them after the button layout; changing one applies immediately.
- **Haptics**: `Input.vibrate_handheld(ms)`, which does nothing off Android.
- **Wiring**: `main.gd` plays the mapped sound for each run event, a click when a menu or panel item is
  activated (`MenuController.activated` signal and the panel choices), a beep when a start light begins and
  the start sound on `RACE_STARTED`.

## Alternatives considered
- Recorded or sampled sounds — licensing and the clean-room rule.
- Runtime synthesis — start-up cost on the handhelds.
- Audio buses and volume sliders — more UI for little value now; the settings are switches.

## Consequences
- Sounds can be re-tuned by editing the script and regenerating; the assets are small (about 1.5 MB).
- The packages include `assets/audio/` (the PortMaster pack already includes the project's resources).
