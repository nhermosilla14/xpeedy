# 16 – Persistence and settings

## Saved progress

Everything is stored locally on the device:

| Data | Contents | Notes |
|---|---|---|
| Stage progress | For each stage: races completed and running score. Also the total races completed overall. | The total only grows. It drives stage unlocking and upgrade unlocks. |
| Upgrades | The purchased level of each of the 7 upgrades | Unlocked levels are not stored; they are recomputed from total races completed |
| Credits | Credits gained (purchases and other sources), credits spent | Balance = gained − spent |
| Personal bests | One per built-in Survival difficulty and one per stage | Only replaced when beaten |
| Custom difficulty | Speed plus 11 on/off toggles ([10](10-survival-mode.md)) | Defaults to speed 100 with everything enabled |
| Flags | First launch done (photosensitivity warning), one-time promotions claimed | |

The original also synchronised progress, upgrades and credits with its online backend, always
keeping the larger value on each side. That is irrelevant offline.

## Settings

| Setting | Values | Default | Effect |
|---|---|---|---|
| Steering | tilt, Zeemote | tilt | Input device ([03](03-movement-and-controls.md)) |
| Invert | on/off | off | Reverses the steering direction |
| Calibrate | on/off | on | Measures the neutral tilt during the start lights |
| Sensitivity | low, medium, high | high | Tilt filter preset |
| Sound | on/off | on | Sound effects |
| Music | on/off | on | Background music |
| Vibrations | on/off | on | Haptic feedback |
| Stereoscopy | off, red/cyan, green/magenta | off | Anaglyph 3D rendering |

Settings are reloaded at the start of every run.

## Pausing and app lifecycle

- If the app goes to the background during a run, it **pauses automatically**.
- While paused, forward motion stops, and the zone, Time Dilation and moving-obstacle timers are frozen.
  **The shield decay, Phase Shift and torpedo reload timers keep running** ([17](17-quirks-and-notes.md)).
- A run in progress is **not saved**. Quitting the app abandons it.
