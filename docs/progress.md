# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-07-02 14:17 JST
- State: `completed`
- Branch: `main`
- Active work: define compatibility interface cleanup milestones.
- Related TODO: `docs/todo.md` `I1: Compatibility Interface Cleanup`.
- Pull request: not opened; documentation and governance preparation only.
- Latest commit: base commit `ccce09e` (`Merge pull request #7`).
- Purpose: make future `$konyak-advance-pr` runs target PR-sized cleanup gates
  for compatibility interfaces that were preserved during earlier nullable and
  boundary refactoring.
- Completed work: added the I1 compatibility cleanup milestone with PR gates for
  CLI parser wrappers, CLI command dispatch, Flutter dialog/picker decisions,
  and Flutter JSON DTO optional fields; moved still-broad follow-up candidates
  to `Deferred`; and updated governance so the new active refactoring milestone
  section is allowed while stale R3/R4 gate entries remain forbidden.
- Remaining work: run `$konyak-advance-pr` to start `I1-P1 CLI Parser
  Compatibility Wrappers` on branch `task/interface-i1-cli-parser-wrappers`.
- Next action: invoke `$konyak-advance-pr` when ready to begin I1-P1.
- Verification: local verification passed with `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint` through the Nix dev
  shell.
