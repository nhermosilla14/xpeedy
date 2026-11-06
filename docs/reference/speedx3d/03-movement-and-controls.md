# 03 – Movement, speed and controls

## Forward speed

The ship moves forward on its own. Speed is expressed as **time per segment (TPS)** in milliseconds.

- Every run **starts at 300 ms per segment** (slow).
- After the start lights go out, the ship accelerates towards the mode's **target TPS**. The original
  acceleration starts strong and fades out; in practice full speed is reached roughly **1 second**
  after the start. See [17](17-quirks-and-notes.md) for a time-based formulation.
- Target TPS per mode:

| Mode | Target TPS (ms) | Approx. segments per second |
|---|---|---|
| Survival Casual | 133 | 7.5 |
| Survival Easy | 100 | 10 |
| Survival Standard | 80 | 12.5 |
| Survival Extreme | 67 | 15 |
| Survival Pure | 50 | 20 |
| Stage races | the race's `speed` × the stage speed factor (see below) | — |

- **Stage speed factor**: stage races use their file's `speed` multiplied by **0.87** (making them about 13 %
  *faster* than the number suggests). The *Flow Control* upgrade changes this factor to **0.95**
  (level 1) or **1.09** (level 2). See [08](08-upgrades.md).
- **Time Dilation** slows the *whole game clock* to 75 % ([06](06-bonuses.md)).
- The game clock never advances by more than 200 ms in a single frame. Longer stalls are replaced by
  the previous frame's duration, so a hitch never teleports the ship.

Speed also drives some obstacle behaviour ([04](04-obstacles.md)):

- rolling-obstacle angular speed = (290 − TPS) degrees per second;
- bouncer oscillation half-period = 1000 − 4 × (TPS − 100) milliseconds.

## Steering

The player controls only the **lateral position** around the tunnel. Steering works like a velocity:
holding a tilt moves the ship sideways continuously.

- Lateral position is tracked on a circle-like scale from −1 to +1 that covers all 16 lanes. Lane
  position = (1 − *p*) × 8, so increasing *p* moves towards lower lane numbers.
- Every frame: *p* changes by (frame seconds) × *steer* × 0.75, where *steer* is the processed tilt below.
- In tube shapes, *p* wraps from +1 to −1 (and back). On flat parts, and during morphs as described
  in [02](02-tunnel-and-world.md), wrapping is a **wall crash** instead.

### Tilt input (the original control scheme)

The device is held in landscape. The accelerometer axis along the device's long side gives a raw
reading in m/s² (about ±9.8 when held vertically):

1. **Zero point**: the raw reading minus the calibrated zero point (see calibration).
2. **Low-pass filter**: an exponential moving average, *acc* ← *k*·*value* + (1 − *k*)·*acc*.
3. **Dead zone**: if |*acc*| ≤ *threshold*, it becomes 0.
4. **Quantisation**: *acc* is rounded to a multiple of *step* (if *step* > 0).
5. **Response curve**: *steer* = sign(*acc*) × |*acc*|^0.66, which softens large tilts.
6. **Invert option**: if "invert" is enabled, *steer* is negated.

Sensitivity presets (setting → *k*, *threshold*, *step*):

| Sensitivity | Smoothing *k* | Dead zone | Step |
|---|---|---|---|
| Low | 0.2 | 0.2 | 0.2 |
| Medium | 0.3 | 0.1 | 0.1 |
| High (default) | 0.4 | 0 | 0.1 |

Higher sensitivity therefore reacts faster, with no dead zone.

### Calibration

If "calibrate" is enabled (the default), the raw tilt is sampled throughout the start-light
countdown. When the lights go out, the samples are sorted and the **mean of the middle 50 %** (the
inter-quartile mean) becomes the zero point. The player can thus hold the device at any comfortable
angle. With calibration disabled, the zero point is 0 (device flat).

### Other inputs

- **Touch**: tapping anywhere fires the held bonus, except on the pause button (top-right) or on the
  upgrade buttons (left edge). Touch is *not* used for steering in the original.
- **Keyboard / D-pad**: the centre, Enter or Space key fires the held bonus. D-pad arrows navigate the menus.
- **Zeemote**: a Bluetooth joystick accessory (since discontinued). Its joystick axis replaced tilt with
  a lighter filter (no smoothing, small step and dead zone), and its buttons fired the bonus and paused.

**Reimplementation suggestion:** add touch or keyboard steering (for example, holding the left or right
half of the screen), feeding a constant *steer* value through the same pipeline from step 5 onwards.

## Camera

- First person: the eye floats **0.1875 units** above the lane surface at the ship's position, looking
  at the point **3 segments ahead** in the same lane.
- Vertical field of view **96°**, near plane 0.1, far plane 100; exponential distance fog in a dark
  purple (RGB ≈ 0.20, 0.06, 0.15).
- The camera's "up" is the surface normal under the ship, smoothed across the current, previous and next segments.
- **Banking**: on flat parts the camera rolls with steering. The target roll is *steer* × π/25 radians,
  and the camera eases towards it at a rate of 5 per second. During a morph the roll blends in or out
  with the morph progress. Tube shapes do not bank.
- **Shake**: the view jitters by up to ±0.015 units while morphing, inside Gravity Well and Plasma
  zones, and for 100 ms each time a rolling obstacle lands.
- Gravity Well also yaws and narrows the camera ([07](07-hazard-zones.md)).
- On a crash, the camera slowly pitches up to 45° over about a second as the game-over screen appears.
