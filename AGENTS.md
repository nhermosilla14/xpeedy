# AGENTS.md

## Project overview
See `README.md` for the project overview, structure, usage and all build/test/lint/run commands,
and `docs/vision.md` for goals.

## Clean-room rule (mandatory)
Gameplay behaviour comes **only** from `docs/reference/speedx3d/`. Never read, decompile or copy the
original SpeedX 3D code, binaries or assets, nor any project derived from them. If the reference is unclear, ask the user.

## Documentation discipline (mandatory)
These rules apply to every change, by humans or agents:

1. **No untracked decisions.** Any decision affecting architecture, dependencies, interfaces, data
   formats, security, deployment or scope MUST be recorded as an ADR in `docs/adr/`
   (copy `docs/adr/0000-template.md`, next sequential number) before the change that implements it.
   Accepted ADRs are never edited; to change one, write a new ADR that replaces it.
   If a decision reverses an earlier one, add a `Replaces: NNNN-title` entry to the new ADR's metadata
   list, mark the old ADR `Superseded by NNNN`, move it to `docs/adr/superseded/`; never delete ADRs. If
   a decision is abandoned without a replacement, mark the ADR `Deprecated` and move it to
   `docs/adr/deprecated/`.
2. **Follow the loop.** Every functional target goes through requirements (intents in `docs/intent/`,
   accepted by the user), design (ADRs in `docs/adr/`, derived from the intents), vertical slices
   (`docs/slices/`, each testable end to end, accepted by the user), then code and test one slice at a
   time. Starting to code accepts the slice's ADRs. Fix every issue found while testing a slice, and
   keep earlier slices' tests passing, before starting the next one. Mark a slice `Done` when its
   end-to-end test passes, and an intent `Done` when all its slices are done and its acceptance
   criteria pass. Accepted slices are never edited; replace them like intents. Accepted intents are
   never edited; to change one, write a replacing intent with a `Replaces: NNNN-title` entry. If an
   intent is dropped, mark it `Dropped` and move it to `docs/intent/dropped/`.
3. **Keep `docs/` current.** Update `docs/architecture.md` when structure or data flow changes,
   `docs/vision.md` when goals/scope change, and `docs/README.md` when docs (including intents and
   slices) are added, removed or moved.
4. **Keep `README.md` current.** Update prerequisites, setup, usage, project structure and
   development guidelines whenever they change. Documented commands must work.
5. **Check before finishing.** Before declaring a task done, review whether docs, README and this
   file need updates, and make them. Mention doc updates in the summary to the user.
6. **Ask, don't invent.** If goals or expectations are unclear, ask the user and record the answer
   in `docs/` instead of assuming.
7. **Tooling and workflow live here, not in ADRs.** Record decisions about tooling (formatters,
   linters, test runners, build/task tools, CI helpers) and workflow (git workflow, branching, commit
   conventions, review and release process) under `## Conventions` below, and edit them in place when
   they change. Commands to run the tools live in `README.md`.
8. **Update this file** when conventions or rules change.

## Conventions
- Tooling: Godot 4.4.1 runs from the `docker.io/barichello/godot-ci:4.4.1` podman image (includes export templates) via `tools/godot.sh`; no host install needed. Tests: own minimal runner (`tests/run_tests.gd`, `TestCase`) plus `tests/e2e_*.gd` scene scripts, run by `tools/test.sh`. Exports via `tools/export.sh`.
- Workflow: trunk-based on `main`, small focused commits, short-lived branches only when needed.
- Style: statically typed GDScript following the official Godot style guide; tabs for indentation.
- Never commit secrets (Android keystores, signing passwords); keep them out of git via `.gitignore`.
