# 0015. Typeface and HUD

- Status: Proposed
- Date: 2026-11-07
- Owner: agent, Nicolás Hermosilla P. (look review)
- Intents: 0004
- ADRs: 0016
- Depends on: slice 0014

## Scope
Orbitron Black becomes the game's typeface. The HUD becomes two dark glass panels flush with the bottom
corners (score, and the common shield bar), a pause button at the top-right, and the "best score" label;
the frame-rate counter moves behind `--fps`.

## Layers touched
- Foundation: `assets/fonts/Orbitron` with `OFL.txt`, a theme that applies the font, the licence copied
  into the PortMaster package.
- View: `GlassPanel` control, `Hud` rebuilt on it, the pause button (drawn; its action comes in slice 0016),
  the best-score label, `--fps`.

## End-to-end test
- Unit and scene tests: the HUD still shows the model's score and shield level (the existing scene tests
  are adapted); the best-score label shows a stored value and fades; the font loads with the weight set; the
  package contains the licence.
- On a real GPU at 480×320 and at a phone-like 2:1 size: screenshots are readable, the panels sit flush in the
  corners, the digits do not overflow.
- Review with the user: side-by-side screenshots of the HUD.

## Out of scope
- Start sequence, pause behaviour, Game Over panel, menus.
