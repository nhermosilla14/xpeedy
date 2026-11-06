# 09 – Scoring and records

## Points

| Source | Points |
|---|---|
| Distance | **+1 per segment travelled** (counted while the run is in progress) |
| Smashing a cube or spike with shields | +100 |
| Smashing a roller or bouncer with shields | +200 |
| Smashing a beam with shields | +300 |
| Quake, torpedo or Phase Shift | 0 (obstacles removed this way give nothing) |

The score is shown on the HUD's left panel. It never goes below zero.

At top speed, distance alone gives about 7.5 points per second on Casual and up to 20 per second on Pure.
Because smashing is rewarded heavily, collecting shields and deliberately ramming obstacles is a core strategy.

### Stage-mode score carries over

In Stage mode the score **accumulates across the races of a stage**. Each race starts with the
stage's running score, and finishing a race saves the new total. Crashing resets the stage's running
score to **0**, while race progress is kept. So a stage's final score rewards finishing all 12 races
without crashing. See [11](11-stage-mode.md).

## Personal bests

Kept separately for:

- each built-in Survival difficulty (Casual, Easy, Standard, Extreme, Pure);
- each Stage, recorded when the stage's final race is finished.

Custom-difficulty runs and challenges have no personal best. The best for the current mode is shown
during the start sequence ("best score: N"), and the end-of-run menu shows the run's score next to
the personal best.

## Achievements and leaderboards (optional)

The original used Google Play Games. A reimplementation can provide equivalents locally:

| Achievement (original name) | Condition |
|---|---|
| Merciless / China Syndrome | Fire 10 Quakes in one run |
| Theory of Relativity | Fire 10 Time Dilations in one run |
| Folded | Fire 5 Space Folds (while a zone is active) in one run |
| Destructoid | Smash 10 obstacles in one run |
| Strong Shields | Smash obstacles on 4 consecutive segments (a chain of 3 back-to-back smashes) |
| Nova Shockwave | Destroy 9 or more obstacles with a single Quake |
| Sharpshooter | Destroy 7 or more obstacles with a single torpedo |
| Fire at Will | Hit a roller or bouncer with a torpedo |
| Time Paradox | Smash a roller or bouncer while Time Dilation is active |
| Plasma Dodger | Get through a whole Plasma Cloud zone without touching plasma or smashing anything |
| Event Horizon | Get through a whole Gravity Well zone without smashing anything, at TPS ≥ 67 |
| Last Frontier | Survive 10 zones in one run |
| Subspace Jump | Finish a Survival run (submitted with the Space Fold count) |
| Chain Warp | Play all four non-Casual built-in Survival difficulties |
| Custom Path | Finish a Custom-difficulty Survival run |
| Endurance (incremental) | +1 per finished run |
| Shattered Horizon (incremental) | Total obstacles smashed |
| Assimilation (incremental, 200) | Total bonuses fired |
| Warp 3 / Warp 6 | Score ≥ 2000 / ≥ 5000 at TPS ≤ 67 |
| At the End of the Universe | Score ≥ 20000 in a challenge |

Leaderboards existed for Survival Standard, Extreme and Pure, and for stages.

The original applied a sanity check before submitting incremental achievements and Survival
leaderboard scores: distance travelled had to exceed one eighth of the score. This rejects runs whose
score came mostly from smashes, which only a manipulated client could produce.
