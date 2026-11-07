# 0033. Race files and the stage catalogue

- Status: Accepted
- Date: 2026-11-07
- Owner: agent
- Intents: 0009
- ADRs: 0024, 0025
- Depends on: slice 0032

## Scope
Race description parsing (doc 11), the 48 race files, the catalogue loader and `RaceSpec`. No generation yet.

## End-to-end test
- Unit tests: every property and syntax of the format (ranges, comments, case, errors, a repeated property, `define` skipped); all 48 files load in order with the speeds, lengths and settings of the table (spot checks and totals); a missing file ends a stage.

## Out of scope
- Generators, the finish, menus.
