# 0041. Keep going

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0010
- ADRs: 0028, 0029
- Depends on: slice 0040

## Scope
The "keep going?" panel after an obstacle crash, the credit cost and the Quake.

## End-to-end test
- Unit tests: only after an obstacle crash, once per run, the run resumes; scene test: yes spends 1 credit and the run goes on, no ends it, a wall crash or a balance under 2 skips the question.

## Out of scope
- New features.

## Results
- The "keep going?" panel after an obstacle crash with at least 2 credits; yes spends 1 and resumes after a
  Quake, no shows Game Over; wall crashes, second crashes and low balances skip it. Model tests are in
  `tests/unit/test_active_upgrades.gd`, the scene flow in `tests/e2e_upgrades.gd` (and `e2e_stage_flow.gd`).
