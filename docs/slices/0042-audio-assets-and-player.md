# 0042. Generated audio and the sound player

- Status: Accepted
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
