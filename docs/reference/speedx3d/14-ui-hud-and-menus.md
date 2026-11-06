# 14 – UI, HUD and menus

All menus are drawn over a slowly flying, animated tunnel with a few cubes drifting past. They are
text menus in a blocky display font. Menus and the HUD are designed for landscape.

## Menu tree

```
Main menu
├── Play ─────────► Mode select
│                   ├── Single ───────► Stage select (4 stages, progress bars, padlocks)
│                   ├── Multiplayer ──► New challenge · Find challenge · Challenge history · Get credits · [Leaderboards] · Help
│                   └── Survival ─────► Casual · Easy · Standard · Extreme · Pure · [Leaderboards]
├── Upgrades ─────► upgrade shop dialog
├── Help ─────────► rules pages (bonuses, zones, upgrades, multiplayer)
├── More games      (store link – obsolete)
├── Get credits     (offer walls / shop – obsolete)
└── [Achievements]  (only when signed in)
Gear icon (bottom-right) ─► Settings
G+ icon (top-right) ──────► sign in / out (obsolete)
Back arrow (bottom-left) on sub-pages
```

- **Play** pulses to draw attention.
- **Settings**: Configure controls ▸ (Steering: tilt or Zeemote · Invert · Calibrate · Sensitivity
  low/medium/high · Configure Zeemote), Sound on/off, Music on/off, Vibrations on/off (when the device
  has a vibrator), Stereoscopy (off, red/cyan or green/magenta), **Configure custom mode**, About.
- **Custom Survival** is configured and launched from *Settings → Configure custom mode*. Closing that
  dialog starts a custom run ([10](10-survival-mode.md)).
- The **upgrade shop** lists the 7 upgrades with icon, name, description, current level, next price and
  a padlock for locked levels. It shows the credit balance and a buy button
  ([08](08-upgrades.md)).
- Menu items react on finger release: the item under the finger highlights while pressed and
  activates when lifted. A click sound plays.

## Run start sequence

1. A fade from black.
2. HUD panels slide in from the edges.
3. "Calibrating sensor" is shown in the middle while tilt samples are collected ([03](03-movement-and-controls.md)).
4. Mode text: Stage races show "STAGE *nn* / RUN *nn*", challenges show "CHALLENGE".
5. "best score: *N*" (or "beat score: *N*" in challenges) appears in the centre, then drifts up.
6. **Three start lights** (red, amber, green), shown left to right, each one second apart, starting
   1.3 s after the run begins. Each light zooms and fades over 0.5 s with a beep. When the last one
   fades, a higher-pitched start sound plays and racing begins.

## In-run HUD

| Element | Position | Behaviour |
|---|---|---|
| Score | Left panel, bottom-left | Current points, right-aligned digits |
| Shields | Right panel, bottom-right | One slot per possible unit (the maximum). Filled slots show the decay level. Gaining or losing a unit animates over 250 ms: a lost unit scales up and fades. |
| Held bonus | Top-left | Ring pulsing in the bonus colour |
| Upgrade buttons | Left edge, stacked | Recharger, Torpedo (with reload dial), Phase Shift; each visible only while usable |
| Pause button | Top-right | Tap to pause |
| Zone warning | Near the top | "Zone change" banner with the zone name and a 3-2-1 countdown |
| Best or target score | Centre, drifting upwards | Shown during the start and the first moments of the run |
| Edge vignette | Whole screen | A subtle darkening "focus" frame |

## In-run menus

| Menu | When | Options |
|---|---|---|
| **Pause** | Pause button, Back key, or the app going to the background | Resume · Restart · Main menu. Challenges allow Resume only. |
| **Game over** | After a crash | New game · Main menu. Shows the score and personal best. |
| **Run finished** | A stage race finished, more races left | Next run · Upgrades (if anything is buyable) · Main menu |
| **Stage finished** | Last race of a stage finished | Upgrades (if anything is buyable) · Main menu. Shows the score and best. |

Choosing "New game" or "Main menu" fades to black before the transition.

## Other screens and dialogs

- **First launch**: a photosensitivity (epilepsy) warning, shown once.
- **Keep going?** dialog after a crash ([13](13-economy.md)).
- **Restart stage?** dialog when selecting a completed stage.
- **Upgrade unlocked** toast after a race, and an "upgrades available" hint after 5 crashes in a row on one race.
- **Back key**: goes back one level in menus. While racing it pauses, and from the pause menu it
  resumes. During the start sequence, after a crash, or on the game-over screen it returns to the main menu.
- Sponsor logo screen (an optional sequence of logos before the first run). Not essential.
