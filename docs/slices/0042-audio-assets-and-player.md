# 0042. Generated audio and the sound player

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0011
- ADRs: 0031
- Depends on: slice 0041

## Scope
`tools/make-audio.py` and the generated WAV files; `SoundPlayer`; `SoundMap`; the music loop.

## End-to-end test
- Unit tests: every asset loads as a non-empty mono 16-bit stream within its expected duration, the music loops, `SoundMap` covers each event of doc 15 with its sound and vibration, the player plays nothing when sound is off and stops the music when music is off, vibration respects its option.

## Out of scope
- Wiring and settings.

## Results
- Slices 0042-0044 were built together: `tools/make-audio.py` and `assets/audio/` (13 effects and a 16 s music
  loop, 948 KB), `SoundPlayer`, `SoundMap`, the wiring in `main.gd`, and the `sound`, `music` and `vibration`
  settings. `tests/unit/test_sound.gd` (9 tests) and `tests/e2e_sound.gd`.
- Godot imports the WAVs compressed (QOA), so the music's loop end is computed from its length. Headless runs
  (the tests) record what would play but make no sound, because live playbacks at exit are reported as leaks.
- Nothing was heard: the sounds are untested by ear, and vibration only exists on Android.
