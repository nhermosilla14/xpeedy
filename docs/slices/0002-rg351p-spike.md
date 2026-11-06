# 0002. RG351P spike: PortMaster package and benchmark

- Status: Done
- Date: 2026-11-05
- Owner: agent, Nicolás Hermosilla P. (on-device run)
- Intents: 0001
- ADRs: 0002
- Depends on: slice 0001

## Scope
Package the walking skeleton as a PortMaster port and measure it on the RG351P, so the engine choice
is validated before more is built on it.

## Layers touched
- Foundation: ARM64 `.pck` export preset, PortMaster port folder (`xpeedy/`: launch script using the
  `godot_4.4.1` runtime with Weston, `port.json`, `gameinfo.xml`, gptk mapping, licenses), build
  script that assembles the zip. Main loop process mode set to Always (4.3+ idle bug).
- View: render at native 480×320, FPS and frame-time readout logged to `log.txt`.

## End-to-end test
- The port zip installs on the RG351P and launches from the Ports menu. D-pad steers, the exit
  hotkey quits.
- Average fps and 1 % low over 60 s are recorded in this slice's notes. Pass: steady ≥ 30 fps.
- On fail: stop and write a superseding ADR (Godot 3.6 fallback) before continuing.

## Out of scope
- Publishing to the PortMaster repository, testing on other handhelds.

## Results (2026-11-05)
- Device: Anbernic RG351P, 480×320, PortMaster with `godot_4.4.1` + `weston_pkg_0.2`.
- Walking skeleton (straight tunnel, fog, FPS label): **47+ fps** sustained, reported by the user.
- Pass (threshold ≥ 30 fps). ADR 0002 stands; no fallback to Godot 3.6 needed.
- Select + Start quits the port.
