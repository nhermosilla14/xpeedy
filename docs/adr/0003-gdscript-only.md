# 0003. GDScript only

- Status: Proposed
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent
- Intent: 0001

## Context
PortMaster Godot runtimes run GDScript-only games out of the box. C# needs a .NET-enabled engine,
extra setup for assemblies on handhelds, and adds memory weight on a 1 GB device. GDExtensions need
native builds for every architecture. The game's per-frame work is small (doc 17).

## Decision
All game code is written in statically typed GDScript. No C#, no GDExtensions.

## Alternatives considered
- C# — heavier runtime, harder PortMaster and Android packaging.
- GDExtension (Rust/C++) — per-platform native builds; not needed for this workload.

## Consequences
- A single `.pck` runs on every runtime.
- If profiling later shows a hot spot, revisit with a new ADR.
