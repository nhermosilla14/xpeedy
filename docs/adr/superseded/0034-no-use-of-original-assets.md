# 0034. No use of the original's assets

- Replaces: 0014-visual-reference
- Status: Superseded by 0036
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P. (requested), agent
- Intent: none (preparing the repository for publication)

## Context
ADR 0014 let the user share images of the original game as a visual reference. Before the repository is
published, the user asked for every reference to the original's assets to be removed from the repository and
its history.

## Decision
- Images and video of the original game are not used as a reference, and the repository does not name or
  link to them.
- The look notes written from those images are removed.
- The clean-room rule (`docs/vision.md`) has no image exception. No asset of the original is copied, traced or
  used; the behaviour reference in `docs/reference/speedx3d/` remains the source of gameplay.
- ADR 0014 is superseded. Its text was removed because it described the original's assets.
- Accepted intents, slices and ADRs keep their decisions. Only links to removed material and wording that
  pointed at the original's images were changed.

## Alternatives considered
- Keep the images out of git (ADR 0014) — the user chose to remove the references altogether.
- Keep ADR 0014's text — it described the original's assets, which the user asked to remove.

## Consequences
- Look decisions are judged on screen by the user, not against images of the original.
- The colour values in `src/view/look.gdshaderinc` were read from those images; they stay as tuning values and
  can be retuned by eye.
