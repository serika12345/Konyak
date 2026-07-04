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

- Timestamp: 2026-07-04 23:05 JST
- State: `completed`
- Branch: `task/type-safety-i3-runtime-install-requests`
- Active work: I3-P5 Runtime Install Request Type Fronts.
- Related TODO: `docs/todo.md` `I3: Mechanical Type-Safety Hardening`,
  completed `I3-P5 Runtime Install Request Type Fronts`; next planned gate is
  I3-P6 macOS Version Capability Type Front.
- Pull request: https://github.com/serika12345/Konyak/pull/28
- Latest implementation commit: `caf1028` (`Type runtime install request constructors`).
- Purpose: remove nullable string and primitive component-archive constructor
  fronts from Konyak-owned macOS/Linux runtime install request wrappers while
  preserving CLI parser strings, update metadata strings, public request
  projections, runtime install behavior, and Wine execution paths.
- Completed work: converted `MacosWineInstallRequest` and
  `LinuxWineInstallRequest` full, repair, component, and update constructors
  to typed `Option<RuntimeArchivePath>`, `Option<RuntimeArchiveUrl>`,
  `Option<RuntimeArchiveChecksumValue>`,
  `Option<RuntimeSourceManifestUrl>`,
  `Option<RuntimeSourceManifestSignatureUrl>`, and
  `Iterable<RuntimeArchivePath>` inputs; kept string projection getters for
  CLI/progress output; updated CLI install parsing and runtime update install
  request construction to adapt external strings into typed request inputs;
  added `packages/konyak_cli/test/runtime_install_request_type_fronts_test.dart`;
  updated CLI contract test fixtures and governance so the converted install
  request fronts cannot regress to primitive constructor inputs.
- Remaining work: review draft PR #28 before starting I3-P6.
- Next action: after the I3-P5 PR is reviewed and merged, run `/advance-pr` to
  start I3-P6 macOS Version Capability Type Front on
  `task/type-safety-i3-macos-version-capability`.
- Verification: I3-P5 implementation verification passed through the Nix dev
  shell with `dart test test/runtime_install_request_type_fronts_test.dart`,
  `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`.
