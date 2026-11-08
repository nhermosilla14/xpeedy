# 0030. The photosensitivity warning and the credits screen

- Status: Superseded by 0033
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P. (requested), agent
- Intent: none (a request between intents 0010 and the next)

## Context
The game has full-screen flashes, strobing zone effects and fast camera motion (docs 14, 15; doc 14 lists a
one-time photosensitivity warning on the first launch). The author also wants the credits in the game: who
developed this clone and the acknowledgement of GameLion, whose SpeedX 3D gave the idea.

## Decision
- **Warning**: the first time the menu opens, a text page says "this game has flashes and visual effects that
  may be triggering for people who are sensitive to them" and has one choice, "i understand". Accepting it saves
  `[flags] warning_seen` in `user://settings.cfg` and the page never shows again. It appears over whatever page
  the menu opens on, and not when a screenshot page is asked for (`--screen`) or in tests.
- **Credits**: "credits" on the main menu opens a text page: "xpeedy: a clone of speedx 3d", "developed by
  nicolas hermosilla", "github: nhermosilla14", "original idea by the great developers at gamelion", with a
  "back" choice (Esc or B also go back). The README has the same credits and the font and licence notes.
- Both pages use `ScreenPanel`; its choices start below the last text line when there are many lines.

## Alternatives considered
- Showing the warning on every launch — annoying; once is what the original did.
- Putting the credits only in the README — the user wants them in the game.

## Consequences
- Resetting the settings file shows the warning again.
- Later text pages (help) can reuse the same page type.
