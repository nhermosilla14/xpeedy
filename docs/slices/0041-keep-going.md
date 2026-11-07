# 0041. Keep going

- Status: In progress
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
