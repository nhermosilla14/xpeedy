# 0012. Help pages

- Status: Done
- Date: 2026-11-08
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0032

## Goal
The original has a Help item in its main menu with the rules (doc 14: bonuses, zones, upgrades). Xpeedy gets
the same: a "help" item that opens a list of topics, each a few short text pages that explain the game as it
is now. The user asked for the help pages while the agent waits on other work; the agent accepted this intent,
its ADR and the slice on that instruction, and the user reviews the result.

## Acceptance criteria
- The main menu has "help" (after "upgrades"); it opens a list of topics: controls, obstacles, shields,
  bonuses, zones, upgrades and modes.
- Choosing a topic shows its text as pages in a panel: a title with the topic and page number, up to six short
  lines, and "next" (or "back" on the last page). Esc, B and the back choice return to the topic list; the topic
  list's back arrow returns to the main menu. Pages are readable at 480×320.
- The text is accurate for the game as built (keys and buttons, what each obstacle, bonus, zone and upgrade
  does, what the modes are), in our own words, all lowercase like the rest of the interface.
- Content is data (`HelpPages`), tested for size limits (at most six lines of at most 28 characters), for
  covering every obstacle, bonus, zone and upgrade by name, and for the topics list.
- The existing behaviour and tests keep working.
- The user reviews it (screenshots).

## Out of scope
- Images or animations in the pages, translations, per-device key hints (the pages name the keyboard and the
  usual gamepad buttons), a context-sensitive help during a run.

## Open questions
- None.
