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

- Timestamp: 2026-07-04 23:38 JST
- State: `completed`
- Branch: `task/type-safety-i3-macos-version-capability`
- Active work: I3-P6 macOS Version Capability Type Front.
- Related TODO: `docs/todo.md` `I3: Mechanical Type-Safety Hardening`,
  completed `I3-P6 macOS Version Capability Type Front`; next planned gate is
  I3-P7 Type-Safety Governance and Lint Guardrails.
- Pull request: not opened yet.
- Latest implementation commit: pending.
- Purpose: replace macOS major-version capability plumbing from primitive
  `Option<int>` to a typed value object while preserving D3DMetal DLSS/MetalFX
  environment selection, terminal setup, CLI JSON, argv, runtime behavior,
  Wine execution paths, and app behavior.
- Completed work: added `MacosMajorVersion` as a bounded integer value object;
  changed `ProgramRunPlanner`, macOS domain/platform request helpers,
  terminal helpers, Wine I/O request adapters, and current-platform planner
  creation to pass `Option<MacosMajorVersion>`; kept OS-version string parsing
  as the I/O adapter boundary; updated D3DMetal DLSS/MetalFX gating to compare
  typed version values; added
  `packages/konyak_cli/test/macos_version_capability_type_fronts_test.dart`;
  updated CLI contract tests and governance so the converted macOS version
  capability plumbing cannot regress to primitive `Option<int>`.
- Remaining work: commit, push, open the I3-P6 draft PR, and review it before
  starting I3-P7.
- Next action: run the I3-P6 verification set, then push
  `task/type-safety-i3-macos-version-capability` and open a draft PR.
- Verification: I3-P6 implementation verification passed through the Nix dev
  shell with `dart test test/macos_version_capability_type_fronts_test.dart`,
  `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`.
