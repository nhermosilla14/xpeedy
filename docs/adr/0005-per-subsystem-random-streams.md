# 0005. Per-subsystem random streams in a deterministic, fixed-step model

- Replaces: 0004-deterministic-gameplay-model
- Status: Accepted
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0001

## Context
ADR 0004 asked for one gameplay generator with a fixed order of draws. Track data (path, parts, and
later obstacles and spots) is generated lazily, on request from whatever needs it first: the mesh
window, the camera look-ahead, collision checks. With a single shared generator, the order of draws
would depend on which consumer asks first, which is fragile across refactors.

## Decision
Everything in ADR 0004 still applies (model/view split, fixed 60 Hz step through a capped, scalable
game clock, own xoshiro128** generator using only 32-bit arithmetic, headless tests), except:

- Each gameplay subsystem owns its **own generator instance**, seeded from the run seed combined
  with a fixed per-subsystem constant (path: the seed itself; parts: `seed ^ 0x5EED0001`; later
  subsystems pick new constants). Inside each subsystem, draws follow a documented fixed order.
- Decoration (camera shake, particles) uses yet another instance, never a gameplay one.

## Alternatives considered
- One shared gameplay generator (ADR 0004) — draw order would depend on request order.
- Pre-generating the whole track up front — endless mode makes that impossible.

## Consequences
- A seed reproduces the same track regardless of the order in which views and systems request it.
- Each new subsystem must declare its seed constant and draw order in `docs/architecture.md`.
