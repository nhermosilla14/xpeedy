# 12 – Multiplayer challenges (historical)

Multiplayer was **asynchronous** and relied on an online backend and Google Play Games sign-in. Both
are gone, so this mode cannot work as originally designed. It is documented so it can be rebuilt
(for example with a self-hosted service, or as local "ghost" challenges).

## Concept

Two players race the **same seeded Survival run**: same track shapes, same obstacles and spots, at the
same difficulty. Whoever scores more wins the wager.

## Flow

1. **Create a challenge**:
   - choose a Survival difficulty (Casual, Easy, Standard, Extreme or Pure);
   - choose a **stake**: 1, 2, 5, 10, 20 or 50 Cr (only affordable stakes can be picked);
   - optionally pick a specific opponent; otherwise the challenge is open to anyone.

   The server supplies an id and a **random seed**. The creator (the *contender*) plays the run, and
   their score is recorded. The stake is held.
2. **Find a challenge**: browse open challenges and accept one by paying the same stake. The
   accepting player (the *contestant*) plays the identical seeded run.
   - The HUD shows "beat score: *N*" until the contestant passes the contender's score, then
     "challenge completed".
3. **Result**:
   - tie: no transfer;
   - contestant scores higher: the contestant receives the prize computed by the server (the
     message shows the profit, prize − stake);
   - otherwise: the contender wins.

   The result is shown in a dialog when it becomes known.
4. **Rematch**: from the challenge history, a lost challenge can be turned into a new challenge
   against the same player, with at least the previous stake.

## Rules specific to challenge runs

- Upgrades apply as in Stage mode, except *Flow Control*. Maximum shields = 3 + *Shields Modulator* level.
- The pause menu allows **only Resume**. Restarting or quitting mid-run is not allowed.
- **Keep going** after an obstacle crash costs **half the stake**. It is offered only if the stake is
  greater than 1 and the balance is greater than half the stake. A contestant is offered it only while
  they have not yet beaten the target, and the message says how many points are still missing.
- No personal best is recorded.

## Leaderboard scoring (original)

Winning a challenge earned leaderboard points by difficulty: Casual 1, Easy 2, Standard 3, Extreme 4,
Pure 5. Winning **your own** challenge doubled them.
