# 0037. Credits, the catalogue and the passive upgrades

- Status: Accepted
- Date: 2026-11-07
- Owner: agent
- Intents: 0010
- ADRs: 0028, 0029
- Depends on: slice 0036

## Scope
`Upgrade` table, `Economy` (persistence, unlocks, buying, rewards), `Upgrades.apply` for decay, maximum shields and the stage speed factor.

## End-to-end test
- Unit tests: prices and totals (430), unlock thresholds, buying in order and only when unlocked and affordable, credits never negative, race counting once, the rewards, applicability per mode, each passive effect on a `RunConfig`, a corrupt file, and that no levels means an unchanged config.

## Out of scope
- The shop, the active upgrades.
