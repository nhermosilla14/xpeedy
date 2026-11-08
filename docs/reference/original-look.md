# The original's look: observations

Written from screenshots of the original game taken on an Android emulator (2026-11-07), as a visual
reference only (ADR 0036). The screenshots are not in the repository. Nothing here is copied: no
textures, fonts, icons or other assets. Colours are approximate values read from the captures. The
original ran in landscape on a phone, roughly 2:1.

## The world

- **Tunnel surface**: cool blue-violet, about `#46448C`–`#524A9A`, with faint wide concentric bands
  (alternately a little darker, about `#3E2D60`, and lighter) that make the ring structure readable
  without hard tile edges. There is no checkerboard.
- **Lane rails**: a thick, soft, bright lavender-white strip (about `#C9C3D1`, blurred edges, roughly a
  quarter of a lane wide) runs along every lane boundary, around the whole ring. They are the main
  speed cue and are brightest at the screen edges. When the path bends, the rails bend with it.
- **Depth**: the vanishing point fades into a dark maroon (about `#2A0A1E`): a warm void against the cool
  walls.
- **Trails**: translucent bands. The fill is a darkened tint of the obstacle colour (for example dark
  brown for amber) and the two lane edges are bright lines of the full colour. The track shows through.
  The colours are saturated: amber, red, green, olive, teal, mauve.
- **Obstacles**: dark glassy bodies (the colour at very low brightness, translucent) with bright
  coloured edge lines, like neon outlines. No visible lighting or textures. Beams are long bars drawn the
  same way, and they cross the tunnel visibly.
- **Shield spots**: a perforated mesh of amber dots on near-black, covering the tile (not a flat orange
  tile).
- **Crash**: a full-screen white flash that fades over about a second, then the frozen scene under the
  Game Over panel.
- **Menu backdrop**: near-black maroon (`#190713`) with a few dark cubes drifting slowly, drawn with
  faintly glowing coloured edges.

## Screens and interface

- **Typeface**: a heavy, geometric, blocky face made of straight strokes and squared curves, all
  lowercase, wide letter spacing in small sizes. Menu items are very large (about a ninth of the screen
  height each).
- **Menu colours**: menu items light grey; the item being pressed turns amber (about `#D8A64A`).
  Titles ("game over", "pause") are amber-orange with a thin dark outline.
- **Menus**: a left-aligned stack at the top-left with no panel behind it, over the drifting-cube
  backdrop. A chunky back arrow at the bottom-left, a settings gear at the bottom-right.
- **Difficulty list**: each entry has a round colour badge showing 1 to 5 dark triangles (cyan, green,
  amber, red, blue), the number of spikes.
- **Pause and Game Over**: a translucent dark-violet rectangle with a thin dark border, centred over the
  frozen scene. Amber title, small white score lines ("score", "personal best"), large light-grey
  choices ("try again", "return to menu").
- **HUD**: two dark glass panels flush with the bottom corners, bottom-left for the score (large white
  blocky digits, right-aligned) and bottom-right for the shields (empty at the start). Each has a light
  top edge. A dark square pause button with two bars at the top-right. A small white label "best score:
  N" at the bottom centre (it drifts upwards and fades as the run starts).
- **Start sequence**: three round indicators at the top centre (white rings around dotted discs) light
  one after another, each swelling and fading. Under them, white labels: the mode ("stage 01 / run 01"),
  "best score: N", and "calibrating accelerometer sensor, please hold still".
- **Loading**: a small bordered square with a spinning ring over a black screen with a drifting cube.

## Not seen yet

The flat ribbon, the outside tube, shield pick-ups and the shield display with shields, held bonuses,
smashes and explosions, hazard zones, rollers and bouncers.
