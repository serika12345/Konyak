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

- Timestamp: 2026-07-04 09:45 JST
- State: `completed`
- Branch: `task/type-safety-i3-runtime-model-fronts`
- Active work: I3-P4 Runtime Model and Source Manifest Type Fronts.
- Related TODO: `docs/todo.md` `I3: Mechanical Type-Safety Hardening`,
  completed `I3-P4 Runtime Model and Source Manifest Type Fronts`; next
  planned gate is I3-P5 Runtime Install Request Type Fronts.
- Pull request: not opened yet.
- Latest implementation commit: pending.
- Purpose: remove primitive constructor fronts from Konyak-owned runtime
  models and source manifests while preserving public CLI JSON strings,
  persisted metadata, runtime-owner manifest strings, runtime install/update
  planning behavior, and Wine execution paths.
- Completed work: converted `RuntimeDefinition`, `RuntimeRecord`,
  `RuntimeStack`, `RuntimeStackBackend`, `RuntimeStackComponent`,
  `RuntimeSourceManifest`, and `RuntimeSourceComponent` constructor fronts to
  existing runtime value objects; kept JSON and source-manifest parsing at
  primitive adapter boundaries; updated runtime platform record construction
  and source archive planning to pass typed values; added
  `packages/konyak_cli/test/runtime_model_type_fronts_test.dart`; updated CLI
  contract test fixtures so public schema strings still build typed runtime
  records for assertions; updated governance so the converted runtime model
  fronts cannot regress to primitive constructors.
- Remaining work: commit, push, open the I3-P4 draft PR, and review it before
  starting I3-P5.
- Next action: run the I3-P4 verification set, then push
  `task/type-safety-i3-runtime-model-fronts` and open a draft PR.
- Verification: I3-P4 implementation verification passed through the Nix dev
  shell with
  `dart test test/runtime_model_type_fronts_test.dart test/runtime_platform_definition_type_fronts_test.dart`,
  `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`.
