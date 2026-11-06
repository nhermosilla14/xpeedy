# Vision

## Purpose
Xpeedy is a free, open-source (GPL-3.0) clone of **SpeedX 3D**, a discontinued first-person tunnel
racer for Android (Gamelion / ByteStorm, 2013–2015). The player steers sideways around a 16-lane,
procedurally curving tunnel at high speed, dodging obstacles. Xpeedy aims to bring that game back on
platforms where it can still be played, including handhelds that the original never ran on.

## Users
- People who played SpeedX 3D and want it back.
- Retro handheld owners (PortMaster), desktop players and Android players looking for a fast,
  short-session arcade game.

## Goals
- Reproduce the original gameplay faithfully: tunnel, track shapes, obstacles, shields, bonuses,
  hazard zones, upgrades, Survival and Stage modes, scoring.
- Run on desktop (Linux, Windows, macOS), Android, and PortMaster handhelds, with the **Anbernic
  RG351P** (RK3326, Mali-G31, 1 GB RAM, 480×320) as the minimum target.
- Support the input each platform offers: tilt and touch on Android, keyboard and mouse on desktop,
  gamepad everywhere.
- Fix the original's documented bugs where the reference recommends it (doc 17).

## Non-goals
- Ads, in-app purchases, offer walls or any monetisation.
- The defunct online challenge service (local alternatives may come later).
- Reusing any code, art, audio or other assets from the original game.

## Constraints
- **Clean-room implementation**: the only source of behaviour is
  [`docs/reference/speedx3d/`](reference/speedx3d/README.md). The original game's code and binaries,
  and any project derived from them, must not be consulted.
- No "SpeedX" branding; all assets are original or under compatible licenses.
- Must stay within the RK3326's performance budget (see ADR 0002).

## Success criteria
- A full Survival run is playable at a stable frame rate on the RG351P, desktop and Android.
- Gameplay values match the reference documents.
