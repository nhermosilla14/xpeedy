# 0032. Help pages as data shown in the menu's text panel

- Status: Accepted
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (requested), agent
- Intent: 0012

## Context
Doc 14 lists a Help item with rules pages. We have a text panel (`ScreenPanel`, ADR 0030) with a title, up to
six lines and choices, and a list page (`MenuScreen`).

## Decision
- **`HelpPages`** (`src/core/help_pages.gd`) holds the content: `topics()` gives the topic names in order and
  `pages(topic)` an array of pages, each an array of lines (at most six lines of at most 28 characters, so a
  page fits the panel at 480×320). The wording is ours, written from the reference notes of the mechanics.
- **Menu**: `MenuController` gets a `HELP` page (a list of the topics; its back arrow returns to the main
  menu) and a `HELP_TOPIC` text page showing one page of a topic with the title "topic n/m" and a single
  choice, "next" or on the last page "back". Esc and B go back to the topic list from any page.
- The main menu's item is "help", between "upgrades" and "credits".

## Alternatives considered
- Markdown or text files loaded at run time — more parsing and files for a few pages; the strings are checked
  by tests when they are code.
- A scrolling single page per topic — needs scrolling input on every device; pages with "next" work with one
  button.

## Consequences
- Adding a topic or a page is one entry in `HelpPages`; the tests keep the pages within the panel.
- Features added later must update the pages (the tests check that the named obstacles, bonuses, zones and
  upgrades are covered).
