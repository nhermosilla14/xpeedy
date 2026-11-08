# 0035. The PortMaster zip is built by GitHub Actions

- Status: Accepted
- Date: 2026-11-08
- Deciders: Nicolás Hermosilla P., agent
- Intent: none (publishing)

## Context
The PortMaster port is a zip built by `tools/package-portmaster.sh` (ADR 0033). Building it by hand on a
workstation is easy to forget and hard to reproduce. The repository is now public on GitHub, so the build can
run there on every change, and a release can carry the zip for PortMaster.

## Decision
- A workflow, `.github/workflows/portmaster.yml`, runs on pushes to `main`, on version tags (`v*`) and by hand.
- It runs in the same image the local tools use (`docker.io/barichello/godot-ci:4.4.1`, Godot 4.4.1 with export
  templates) as the job container, and runs `tools/package-portmaster.sh` unchanged.
- To run the local `godot` binary, `tools/godot.sh` honours `GODOT_LOCAL=1` (set by the workflow), so no nested
  podman container is needed. Without the variable it runs podman as before.
- Every run uploads `xpeedy.zip` as the artifact `xpeedy-portmaster`. A `v*` tag also creates a GitHub release
  with the zip attached.
- Only the packaging is automated. Tests and the art generation (`tools/make-portmaster-art.sh`, which needs a
  display) are not part of the workflow.
- Actions are pinned to major versions: `actions/checkout@v4`, `actions/upload-artifact@v4`,
  `actions/download-artifact@v4` and `softprops/action-gh-release@v2`, the last being the one third-party action.

## Alternatives considered
- Installing Godot directly on `ubuntu` runners — the export templates and the version would need to match the
  image by hand; the image already pins both.
- Podman on the runner — rootless podman on hosted runners is less predictable than running inside the image.
- Building the zip on tags only — the artifact on every push shows whether the build still works.

## Consequences
- A release is made by pushing a tag such as `v0.9.0`. The version in `project.godot` should match the tag.
- The first run after the workflow lands has to be checked on GitHub's Actions page; the workflow can only be
  run there.
- The art (cover, screenshot, preview video) is committed in `packaging/portmaster/`. The packaging script copies it
  to `build/portmaster/submission/`, but only `xpeedy.zip` is uploaded or released.
