# 0038. Upgrades shop and credit rewards

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0010
- ADRs: 0028, 0029
- Depends on: slice 0037

## Scope
The main menu entry and `UPGRADES` page with levels, prices, padlocks and balance; rewards paid on finishing races, finishing a stage and ending a Survival run; the panels' "upgrades" choice; the economy used in `main.gd`.

## End-to-end test
- Scene test: finishing a new race pays and counts, the shop buys an upgrade and the next race uses it, a locked level cannot be bought, the panel offers upgrades when affordable; screenshot of the shop.

## Out of scope
- Active upgrades, keep going.

## Results
- `upgrades` on the main menu and the `UPGRADES` page (levels as a bar, the next price or "max", a padlock,
  the balance as a footer); credits paid on finishing a new race, finishing a stage and ending a Survival run;
  upgrades applied to plain runs; the finished panels list "upgrades" when something is buyable.
  `tests/e2e_shop.gd`; capture `build/look/m-upgrades.png`. The scene tests use temporary economy files.
- The upgrades apply to plain runs only; debug and benchmark runs ignore them and never pay credits.
