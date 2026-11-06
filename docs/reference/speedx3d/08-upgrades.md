# 08 – Upgrades

Upgrades are permanent improvements bought with credits ([13](13-economy.md)). Each has up to 3
levels, bought in order. A level can be bought only once it is **unlocked** by progress in Stage mode.

## Where upgrades apply

- **Stage races** and **Challenges**: all upgrades.
- **Survival Casual, Easy and Standard**: all except *Flow Control* and *Shields Modulator*.
- **Survival Extreme, Pure and Custom**: no upgrades. The run uses base values.

## Catalogue

| Upgrade | Levels | Prices (Cr) per level | Effect | Type |
|---|---|---|---|---|
| **Flow Control** | 2 | 15, 30 | Slows Stage races. The speed factor is 0.87 by default, 0.95 at level 1 and 1.09 at level 2 (TPS is multiplied by it, so higher is slower). Described in-game as −10 % / −25 %. | Passive, Stages only |
| **Fractal Shields** | 3 | 15, 20, 35 | Shield decay timer 20 s → 21 / 23 / 25 s | Passive |
| **Shields Modulator** | 2 | 25, 40 | Maximum shields 3 → 4 / 5 | Passive, Stages and Challenges only |
| **Shield Recharger** | 3 | 20, 25, 35 | **Once per run**, tap to add 1 / 2 / 3 shield units (up to the maximum) | Active |
| **Tachyon Torpedo** | 3 | 15, 30, 45 | 1 / 2 / 3 torpedoes per run, fired by tapping | Active |
| **Phase Shift** | 2 | 25, 55 | **Once per run**, tap to pass through obstacles for 5 / 10 s | Active |
| **Tachyon Boost** | 2 | 10, 15 | Described as "torpedo reload −25 % per level". **It has no effect in the original game.** | Passive |

## Unlock schedule

Driven by the **total number of races completed** in Stage mode (a counter that never goes down):

| Races completed | Newly unlocked |
|---|---|
| 0 (start) | Level 1 of Flow Control, Fractal Shields, Shields Modulator, Shield Recharger, Tachyon Torpedo, Tachyon Boost |
| 7 | Shield Recharger 2 |
| 12 | Fractal Shields 2 |
| 15 | Phase Shift 1 |
| 20 | Flow Control 2 |
| 24 | Fractal Shields 3 |
| 26 | Tachyon Torpedo 2 |
| 33 | Shields Modulator 2 |
| 36 | Phase Shift 2 |
| 38 | Tachyon Boost 2 |
| 40 | Tachyon Torpedo 3 |
| 42 | Shield Recharger 3 |

A toast announces new unlocks when a race is finished. After 5 crashes in a row on the same race,
the game suggests buying upgrades, if any are affordable and unlocked.

## Active upgrades in a run

Active upgrades appear as **buttons on the left edge** of the HUD, stacked from the top: Recharger,
Torpedo, Phase Shift. A button is shown only while it can be used.

### Shield Recharger

Tapping it adds its strength in shield units, capped at the maximum. It plays the shield-up sound,
gives a 150 ms vibration and restarts the shield decay timer. The button then disappears for the rest
of the run. If the shields are already full, nothing is added, but the decay timer still restarts and
the button is used up.

### Tachyon Torpedo

- **Fire**: a torpedo launches along the ship's current lane position with a flash and a launch sound.
- **Flight**: it travels down the tunnel twice as fast as the ship, until it is 25 segments ahead.
  Everything in its path is destroyed: cubes, beams (including the opposite end of a beam inside a
  tube), spikes, rollers and bouncers. A hit means within ±0.4 lanes and 0.4 segments of its path.
  Torpedo kills give **no points** and cost no shields.
- **Reload**: if torpedoes remain, the next one reloads starting at the moment of firing. Reload takes
  100 ÷ 1.25^*L* segments of travel time, where *L* is the *Tachyon Torpedo* level: 80 segments at
  level 1, 64 at level 2, 51.2 at level 3. A clock-style progress dial is drawn on the button.

### Phase Shift

On activation: a white flash and a 150 ms vibration. For 5 s (level 1) or 10 s (level 2), obstacles
and plasma are ignored ([05](05-shields-and-collisions.md)), obstacles are drawn translucent and trails
are dimmed. Short white flashes warn at 2 s and at 1 s remaining, and another flash marks the end.
Usable once per run.
