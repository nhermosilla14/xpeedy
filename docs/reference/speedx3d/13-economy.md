# 13 – Economy (credits)

## Balance

The player has a single **credits (Cr)** balance: credits gained minus credits spent. It never goes
negative, and a purchase is refused if the balance is too low.

## Sources in the original game

**Normal gameplay never awards credits.** In the original, every credit came from outside the races:

| Source | Amount |
|---|---|
| In-app purchase packs | 25, 80, 200 or 500 Cr |
| Offer walls and rewarded video ads | Variable |
| Winning a multiplayer challenge | The pot ([12](12-multiplayer-challenges.md)) |
| One-time promotions | 15 Cr (partner promotion), 5 Cr (first social share) |

None of these work today, since the stores, ad networks and servers are gone.

## Sinks

| Sink | Cost |
|---|---|
| Upgrades ([08](08-upgrades.md)) | 10–55 Cr per level, **455 Cr** to max everything |
| "Keep going" after a crash: Survival and Stage | **1 Cr**, offered only when the balance is ≥ 2 |
| "Keep going" after a crash: Challenges | half the stake |
| Challenge stakes | 1–50 Cr |
| "Remove ads" (original monetisation) | Credits or a purchase. Irrelevant without ads. |

### Keep going

After an **obstacle** crash, but not a wall crash, a dialog asks "Would you like to continue for *N* Cr?":

- **Yes**: the credits are spent, a **Quake** clears every obstacle in view, and the run resumes from
  the same spot. Shields are unchanged; usually there are none left, since the crash happened.
- **No**: game over.

It is offered **at most once per run**. A second crash after continuing always ends the run.

## Recommendations for a reimplementation

Without external sources, upgrades would be unreachable. Pick a gameplay reward, for example:

- credits per race finished (scaled by stage), and a bonus for finishing a stage;
- credits per N points in Survival;
- or make upgrades unlock-only (free once unlocked by race progress).

Keep the existing prices and unlock schedule for balance.
