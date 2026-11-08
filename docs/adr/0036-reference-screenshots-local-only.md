# 0036. Reference screenshots: local visual reference, never published

- Replaces: 0034-no-use-of-original-assets
- Status: Accepted
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (decided), agent
- Intent: none (clean-room rules)

## Context
ADR 0014 let the author keep screenshots of the original game as a visual reference, outside git. Before the
repository was published, ADR 0034 went further and stopped any use of the original's images, and the look notes
made from them were removed. The concern is publishing and copying, not looking: a visual reference does not put
any asset into the game.

## Decision
- Screenshots of the original game may be used as a visual reference for the look. They stay on the author's
  machine in `reference-screenshots/`.
- They are never committed or published. `.gitignore` keeps `/reference-screenshots/` out of git.
- No asset of the original is copied, traced or used verbatim (textures, models, fonts, icons, sounds). Gameplay
  still comes only from `docs/reference/speedx3d/`.
- The look notes in `docs/reference/original-look.md` are restored. They describe colours and layout in our own
  words and contain no asset.
- ADR 0034 is superseded and moved to `docs/adr/superseded/`. The text of ADR 0014 was replaced by a stub in the
  published history (ADR 0034); this record restates its decision.

## Alternatives considered
- Keep ADR 0034 (no use of the images at all) — too strict: the images are useful for judging the look, and the
  risk is only in publishing or copying them.
- Keep the screenshots out of the repository entirely, with no notes — loses the reference for the look.

## Consequences
- Agents may read the screenshots in `reference-screenshots/` when judging the look, and must not publish or copy
  from them.
- Records that say the look notes were removed (ADR 0034 and the accepted intents and slices that point at it) refer
  to that removal, which this ADR reverses.
