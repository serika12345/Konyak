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

- Timestamp: 2026-06-25 21:28 JST
- State: `in_progress`
- Branch: `main`
- Active work: releasing Konyak v1.0.3.
- Related TODO: none; user-requested release.
- Purpose: bump the packaged app version to 1.0.3, publish the release tag, and
  keep GitHub Actions green before considering the release complete.
- Completed work: bumped the Flutter package version to `1.0.3+4`, updated the
  CLI packaged app version to `1.0.3`, updated focused app-update coverage, and
  made the macOS release script remove stale versioned artifacts so local
  release smokes stay repeatable after a version bump.
- Remaining work: commit and push the release bump, create/push `v1.0.3`,
  monitor every triggered GitHub Actions workflow, and fix or rerun failures
  until all CI is successful.
- Next action: rerun full verification after the release tooling change, then
  commit and push the v1.0.3 release bump.
- Verification: focused `dart test test/cli_contract_test.dart --plain-name
  "app update checker defaults to the packaged Konyak app version"` failed as
  expected before the version constant was updated, then passed after the bump;
  focused `flutter test test/macos_window_metrics_test.dart --plain-name "macOS
  release bundles zstd extraction support for runtime stacks"` failed before
  the stale-artifact cleanup and passed after; `just verify-governance`; `just
  verify-safety`; `just format-check`; `just lint`; `just cli-test`; `just
  flutter-test`; `just macos-release`; final-release-app macOS smokes passed:
  `smoke_macos_release_runtime_extraction.zsh`,
  `smoke_macos_dmg_layout.zsh`, `smoke_macos_finder_integration.zsh` with the
  PuTTY fixture, `smoke_macos_packaged_app_cli_bridge.zsh`, and
  `smoke_macos_app_update_handoff.zsh`. Linux release verification is deferred
  to GitHub Actions because the local host is macOS.
