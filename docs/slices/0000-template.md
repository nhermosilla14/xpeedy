# NNNN. Title

- Replaces: <NNNN-title, comma-separated if several; omit if nothing is replaced>
- Status: Proposed | Accepted | In progress | Done | Dropped | Superseded by NNNN
- Date: YYYY-MM-DD
- Owner: <names / agent>
- Intents: <NNNN, NNNN> (intents this slice fully or partly delivers)
- ADRs: <NNNN, NNNN> (decisions this slice implements)
- Depends on: <slice NNNN, NNNN; omit if none>

## Scope
What this slice delivers end to end, described as user-visible or externally testable behavior.

## Layers touched
- Foundation / infrastructure: the minimum needed for this slice.
- Services / backend: what is added or changed.
- UI / interface: just enough to exercise the slice.

## End-to-end test
- Concrete, verifiable scenario that proves the slice works through every layer, mapped to the
  intents' acceptance criteria it covers.

## Out of scope
- What is deliberately left for later slices.
