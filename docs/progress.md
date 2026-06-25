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

- Timestamp: 2026-06-25 21:52 JST
- State: `completed`
- Branch: `main`
- Active work: releasing Konyak v1.0.3.
- Related TODO: none; user-requested release.
- Purpose: bump the packaged app version to 1.0.3, publish the release tag, and
  keep GitHub Actions green before considering the release complete.
- Completed work: bumped the Flutter package version to `1.0.3+4`, updated the
  CLI packaged app version to `1.0.3`, updated focused app-update coverage, and
  made the macOS release script remove stale versioned artifacts so local
  release smokes stay repeatable after a version bump. Commit `edb3d60`
  (`Prepare v1.0.3 release`) is pushed to `main`, and annotated tag `v1.0.3`
  was pushed for the same commit. GitHub Actions then exposed two release
  blockers: Ubuntu Flutter golden drift for Japanese text goldens and Linux
  runtime CLI smoke falling back to the Nix dev-shell default local source
  manifest path after `nix develop`. Commit `2d6b400` (`Fix v1.0.3 CI
  checks`) fixed those blockers and the `v1.0.3` tag was moved to that release
  commit.
- Remaining work: none for v1.0.3.
- Next action: resume from `docs/todo.md` for the next product task.
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
  to GitHub Actions because the local host is macOS. After pushing
  `edb3d60`, GitHub Actions showed `Konyak Verify` failing on Ubuntu with
  `goldens/pin_program_action_ja.png` at 10.01% diff and
  `goldens/app_settings_dialog_language.png` at 2.25% diff, and `Linux Runtime
  CLI Smoke` failing because the dev-shell default
  `.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json`
  path was propagated to the resolver even when that default manifest did not
  exist. CI fix verification performed: `just verify-governance` failed as
  expected after adding the governance assertion, then passed after the Linux
  smoke script fix; `zsh -n scripts/run_linux_runtime_cli_smoke.zsh
  scripts/prepare_linux_dev_runtime_source.zsh
  scripts/resolve_linux_runtime_source_manifest.zsh`; focused `flutter test
  test/widget_test.dart --plain-name "Japanese pin program action keeps the
  requested line break"`; focused `flutter test test/widget_test.dart
  --plain-name "settings dialog language selector matches golden"`; `just
  verify`; `git diff --check`. Final GitHub Actions for commit `2d6b400`
  succeeded: `Konyak Verify` on `main`, `Konyak Pages` on `main`, `Linux
  Runtime CLI Smoke` on `main`, `Konyak Verify` on `v1.0.3`, and `Konyak
  Release` on `v1.0.3`.
