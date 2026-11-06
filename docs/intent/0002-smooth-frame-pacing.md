# 0002. Smooth frame pacing on the RG351P

- Status: Done
- Date: 2026-11-06
- Owner: Nicolás Hermosilla P., agent
- Related ADRs: 0007

## Goal
The tunnel prototype feels smooth on the RG351P: no visible hitches while the tunnel scrolls,
curves or changes shape, leaving CPU headroom for the obstacles, pick-ups and effects still to come.

## Acceptance criteria
- On the RG351P (480×320, PortMaster), over 60 s of play that includes at least two shape changes:
  average ≥ 58 fps and 1 % low ≥ 50 fps in every 10 s `[bench]` window.
- The user confirms there are no noticeable hitches during shape changes.
- Behaviour is unchanged: everything intent 0001 accepted still holds, and all its tests pass.
- Per-tick CPU cost of drawing the tunnel no longer grows during morphs (measured on desktop).

## Out of scope
- New gameplay or visuals.
- Other handhelds (they are faster than the RK3326).

## Open questions
- None.
