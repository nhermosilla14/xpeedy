# 0004. Look and interface close to the original

- Status: Done
- Date: 2026-11-07
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0014, 0015, 0016, 0017

## Goal
Xpeedy looks and feels like the original SpeedX 3D, as closely as we can get from the observations in
the look notes removed by ADR 0034 (no
asset is copied). The world, the HUD and the end-of-run screen change; the rules do not. Details we could
not observe (the flat ribbon and outside tube close up, smash and explosion, shield display with shields,
bonuses, hazard zones) follow the same style by extension and are refined later.

## Acceptance criteria

### The world
- The tunnel surface is blue-violet with faint wide concentric bands and no checkerboard. The vanishing
  point fades into a dark maroon void.
- A thick, soft, bright lavender-white rail runs along every lane boundary, on every shape (inside, flat
  and outside), following the path's bends, with blurred edges.
- Trails are translucent: a darkened tint of the obstacle colour as the fill, and bright edge lines of
  the full colour on the lane borders, so the track shows through. Fade-in and the red-orange highlight
  keep their rules (doc 04).
- Obstacles are dark translucent-looking bodies with bright coloured edge lines (cubes, beams and
  spikes), with no lighting. Beams cross the tunnel visibly.
- Shield spots are a perforated mesh of amber dots on near-black.
- Explosion fragments and flashes keep the doc 15 colours, restyled to match (fragments as dark bodies with
  bright edges in the obstacle's colour).

### The interface
- A bundled open-licence typeface in the spirit of the original: heavy, blocky, geometric, lowercase.
  Its licence file ships with every package.
- **HUD**: the score in a dark glass panel flush with the bottom-left corner (large digits,
  right-aligned), the shield bar in a matching panel flush with the bottom-right corner, both with a light
  top edge; a pause button at the top-right; a small "best score: N" label at the bottom centre that
  fades after the start. The frame-rate counter is shown only when a debug option is on.
- **Start sequence**: three round dotted indicators at the top centre light one after another, each
  swelling and fading (doc 14), with the mode label and the best-score label; racing starts when the last
  one fades. (No sensor calibration message yet.)
- **Game Over**: a translucent dark-violet panel over the frozen scene with an amber "game over" title,
  the score and the personal best in small white type, and "try again" in large light-grey type; the
  crash flash plays first (doc 15). The personal best for Survival Standard is saved on the device.
- Everything is readable at 480×320, scaled by screen height as before.

### Constraints
- The existing rules, tests and the restart control keep working. All earlier acceptance criteria of
  intents 0001–0003 still hold.
- On the RG351P at 480×320, with `--benchmark`, every 10 s window keeps an average of at least 58 fps and
  a 1 % low of at least 50 fps (as in intents 0002 and 0003).
- No asset of the original is used: the font, the dotted pattern and every shape are our own or
  open-licence.
- The user reviews the look on screen and confirms it is close.

## Out of scope
- Main menu, mode and difficulty screens, the pause menu's choices beyond a pause button, settings, and
  the app flow between them (next intent).
- Sound and music.
- Rollers, bouncers, bonuses and hazard zones (they come later and follow this style).
- A pixel-exact match: unobserved details are refined later.

## Open questions
- None. Decisions taken with the user (2026-11-07): an open font that looks similar is fine; follow the
  original's style as closely as possible; go with what has been observed and refine the rest later.
