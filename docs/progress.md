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

- Timestamp: 2026-07-03 23:03 JST
- State: `completed`
- Branch: `task/type-safety-i3-runtime-platform-definitions`
- Active work: I3-P3 Runtime Platform Definition Type Fronts.
- Related TODO: `docs/todo.md` `I3: Mechanical Type-Safety Hardening`,
  completed `I3-P3 Runtime Platform Definition Type Fronts`; next planned gate
  is I3-P4 Runtime Model and Source Manifest Type Fronts.
- Pull request: https://github.com/serika12345/Konyak/pull/26
- Latest implementation commit: `b1efd7a` (`Type runtime platform definitions`).
- Purpose: remove primitive constructor fronts from Konyak-owned runtime
  platform definition catalogs while preserving public CLI JSON strings,
  runtime-owner manifest strings, install planning behavior, runtime
  validation behavior, and Wine execution paths.
- Completed work: converted `RuntimePlatformSpec`,
  `RuntimeStackComponentDefinition`, and `RuntimeBackendDefinition` catalog
  fields to existing runtime value objects; updated Linux/macOS platform
  catalogs to construct typed definitions; projected typed values back to
  primitive strings only at CLI JSON, runtime model, install-plan, and host
  environment boundaries; added
  `packages/konyak_cli/test/runtime_platform_definition_type_fronts_test.dart`;
  updated governance so the converted platform definition constructor fronts
  cannot regress to primitive fields.
- Remaining work: review draft PR #26 before starting I3-P4.
- Next action: after the I3-P3 PR is reviewed and merged, run `/advance-pr` to
  start I3-P4 Runtime Model and Source Manifest Type Fronts on
  `task/type-safety-i3-runtime-model-fronts`.
- Verification: I3-P3 implementation verification passed through the Nix dev
  shell with the focused runtime platform definition test, `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint`.
