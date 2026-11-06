# 0001. Record architecture decisions

- Status: Accepted
- Date: 2026-11-05
- Deciders: Nicolás Hermosilla P., agent

## Context
Xpeedy targets several platforms and is built by a human working with coding agents. Decisions and
goals must be written down so any contributor can pick up the work without re-deriving them.

## Decision
- Architecture decisions are recorded as ADRs in `docs/adr/`.
- Functional goals are recorded as intent records in `docs/intent/`.
- Work is planned and delivered as vertical slices in `docs/slices/`.
- The workflow and immutability rules are described in `AGENTS.md`.

## Alternatives considered
- Undocumented decisions in commit messages — hard to find and easy to lose.

## Consequences
Every architecture-relevant change needs an ADR first. Accepted records are never edited, only superseded.
