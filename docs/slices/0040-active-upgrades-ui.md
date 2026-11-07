# 0040. Active upgrades: buttons, input and look

- Status: Done
- Date: 2026-11-07
- Owner: agent
- Intents: 0010
- ADRs: 0028, 0029
- Depends on: slice 0039

## Scope
The three actions, the HUD buttons with the reload dial, the torpedo projectile, Phase Shift dimming, flashes.

## End-to-end test
- Scene test: a recharge, a torpedo and a Phase Shift through the actions; the buttons show only while usable; shaders compile; screenshots.

## Out of scope
- Keep going.

## Results
- Actions `recharge`, `torpedo`, `phase` (Q, W, E; gamepad X, Y, R1), the HUD buttons on the left edge with the
  reload dial and the torpedo count, `TorpedoView` (a small bright sphere), the `phase_shift` global uniform
  (dim trails, faint obstacles), flashes, `--all-upgrades`. Capture `build/look/upgrades-hud.png` shows the
  buttons; the torpedo and the Phase Shift look are not captured. The shader global is called `phase_shift`
  because the obstacle shader already has a local `phase`.
