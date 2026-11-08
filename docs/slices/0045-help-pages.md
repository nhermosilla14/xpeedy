# 0045. Help pages

- Status: Done
- Date: 2026-11-08
- Owner: agent, Nicolás Hermosilla P. (review)
- Intents: 0012
- ADRs: 0032
- Depends on: slice 0044

## Scope
`HelpPages` content, the `HELP` and `HELP_TOPIC` menu pages, the main menu item.

## End-to-end test
- Unit tests: the topics and their size limits, coverage of every obstacle, bonus, zone and upgrade name, the
  page flow (next, back, Esc), the menu entry.
- Screenshots of the topic list and two pages (user review).

## Out of scope
- Images, translations, context help.

## Results
- `HelpPages` (7 topics, 15 pages), the `HELP` and `HELP_TOPIC` pages, the "help" item; `tests/unit/test_help.gd`
  (5 tests: sizes, coverage of every obstacle, bonus, zone and upgrade name, the page flow). `--screen=help` and
  `--screen=help:<topic>:<page>` open them for screenshots; captures `build/look/h-*.png` at 480x320 fit.
