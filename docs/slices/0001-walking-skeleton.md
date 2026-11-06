# 0001. Walking skeleton: straight tunnel with steering

- Status: Done
- Date: 2026-11-05
- Owner: agent
- Intents: 0001
- ADRs: 0002, 0003, 0004

## Scope
A Godot 4.4 project that opens a window and flies through a straight, endless 16-lane tube. The
player steers around it with keyboard or gamepad and the tunnel wraps at the seam. Speed eases from
300 ms to 80 ms per segment over 1 s. An on-screen FPS counter is shown.

## Layers touched
- Foundation: Godot project (Compatibility renderer, 60 Hz physics, input map), PCG32, run clock,
  headless test runner.
- Model: `TrackModel` (segment window, ship position, speed ease), steering pipeline from step 5 on
  (response curve, invert).
- View: `TunnelView` ArrayMesh grid rebuilt as segments scroll, first-person camera, fog, FPS label.

## End-to-end test
- Headless unit tests pass: PCG32 known sequence, speed reaches 80 ms at 1.0 s game time,
  lane position = (1 − *p*) × 8, wrap from +1 to −1 in a tube, 200 ms clock cap.
- Running the project: the tube scrolls continuously, holding left/right rotates the view around
  the tube, crossing lane 15 ↔ 0 wraps without a crash.

## Out of scope
- Curves, shapes, morphs, crashes, PortMaster packaging.
