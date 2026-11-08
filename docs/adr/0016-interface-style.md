# 0016. Interface style: typeface, HUD panels and screen panels

- Status: Accepted
- Date: 2026-11-07
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0004

## Context
The original's interface uses a heavy, squared, lowercase typeface, dark
glass panels flush with the bottom corners for the score and the shields, a pause button, white labels,
and a centred translucent panel for Pause and Game Over. We need an open-licence typeface and a way to
build these in Godot that scales from 480×320 to a phone.

## Decision
- **Typeface**: Orbitron (SIL Open Font License 1.1) at its Black weight (900). Of thirteen open fonts
  compared against the look notes it is the closest: heavy, squared, geometric,
  lowercase. Runner-up: Oxanium ExtraBold. Orbitron is a variable font, so the weight is set with a
  `FontVariation`. The font and its `OFL.txt` are bundled in `assets/fonts/`, and the licence is shipped in
  every package (PortMaster `licenses/`, desktop and Android builds).
- **Scale**: one unit is the viewport height ÷ 320, as before (doc 17). Sizes below are in units at 320 px.
- **Colours**: menu and panel text light grey `#C4BFC4`; pressed or highlighted amber `#D8A64A`; titles amber
  `#E2A63A` with a thin dark outline; white labels `#F1F1F4` with grey text `#9A98A4`; panel fills dark
  navy `#1D1A3E` at 90 %, with a light top edge `#C9C4D5` and a thin dark outline; screen panels dark violet
  `#2B2160` at 70 %.
- **HUD**:
  - Score panel flush with the bottom-left corner (about 24 % of the width, 14 % of the height), score
    right-aligned in white at about 24 units.
  - Shield panel of the same size flush with the bottom-right corner, holding the common shield bar of ADR 0012.
  - A pause button, a dark square about 22 units with two white bars, at the top-right.
  - A white label "best score: N" at the bottom centre, shown through the start sequence and the first
    three seconds of the race, then faded out.
  - The frame-rate counter appears only with the debug option `--fps`.
- **Screen panels** (Game Over, Pause): a centred translucent rectangle (about 72 % × 60 % of the screen)
  with a 1 unit dark border: title in amber at about 40 units, small white lines ("score: N", "personal
  best: N") at about 12 units, choices at about 26 units in light grey, amber while pressed. Choices react
  to mouse and touch; the keyboard and gamepad keep the existing actions (restart, pause). Full menu
  navigation comes with the menus intent.
- **Start lights**: three round indicators at the top centre (a white ring around a disc of small dots),
  one per second from 1.3 s, each swelling to about 1.6× and fading over 0.5 s; under them white labels
  with the mode and "best score".
- **Implementation**: the panels are drawn by one `GlassPanel` control (fill, outline, top edge) used by
  every panel; the dotted discs are drawn procedurally. No image assets.

## Alternatives considered
- A bitmap or pixel font drawn from an image — needs an asset and scales badly across screens.
- Oxanium ExtraBold — lighter than the original.
- Per-widget bitmap skins — assets again.

## Consequences
- One typeface and one panel control define the whole interface; the menus intent reuses them.
- A bundled font adds about 40 KB and the licence obligations above.
- Orbitron Black is wider than the original's letters, so long lines (for example "return to menu") need
  size checks at 480×320.
