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

- Timestamp: 2026-07-03 21:54 JST
- State: `completed`
- Branch: `task/type-safety-i3-runner-kind-catalog`
- Active work: I3-P2 Runner Kind Typed Catalog.
- Related TODO: `docs/todo.md` `I3: Mechanical Type-Safety Hardening`,
  completed `I3-P2 Runner Kind Typed Catalog`; next planned gate is I3-P3
  Runtime Platform Definition Type Fronts.
- Pull request: https://github.com/serika12345/Konyak/pull/25
- Latest implementation commit: `ad17606` (`Add runner kind catalog`).
- Purpose: remove ad hoc runner-kind string construction from request builders
  by centralizing stable Konyak-owned runner kinds in a typed catalog while
  preserving public `runnerKind` JSON strings, argv, exit codes, runtime
  behavior, Wine execution paths, and app behavior.
- Completed work: added the `RunnerKind` stable request catalog; replaced
  direct `RunnerKind('<literal>')` construction in domain, platform, and I/O
  request builders plus focused tests; added
  `packages/konyak_cli/test/runner_kind_catalog_test.dart`; updated governance
  so request builders cannot reintroduce direct runner-kind literal
  construction.
- Remaining work: review draft PR #25 before starting I3-P3.
- Next action: after the I3-P2 PR is reviewed and merged, run `/advance-pr` to
  start I3-P3 Runtime Platform Definition Type Fronts on
  `task/type-safety-i3-runtime-platform-definitions`.
- Verification: I3-P2 implementation verification passed through the Nix dev
  shell with `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`.
