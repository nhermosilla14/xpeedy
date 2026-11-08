# 0043. Sounds and music in the game

- Status: Accepted
- Date: 2026-11-07
- Owner: agent
- Intents: 0011
- ADRs: 0031
- Depends on: slice 0042

## Scope
`main.gd` plays the sounds for run events, menu clicks, start lights and the start sound, and starts the music; vibration on the events of doc 15.

## End-to-end test
- Scene test: playing through a run (pick-ups, smash, bonus, zone, finish, crash) records the expected sounds in order and the music is playing; menu activation records a click.

## Out of scope
- The settings items.
