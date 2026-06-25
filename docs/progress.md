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

- Timestamp: 2026-06-25 23:06 JST
- State: `in_progress`
- Branch: `main`
- Active work: updating the v1.0.3 release after fixing the Linux AppImage
  startup failure.
- Related TODO: Linux AppImage distribution reliability; user-reported defect;
  v1.0.3 release update.
- Purpose: ensure GitHub Release publishing is gated on the release workflow's
  repository verification, include the Linux AppImage loader fix in v1.0.3, and
  keep the release incomplete until GitHub Actions pass.
- Completed work: reproduced the initial `permission denied` failure because
  the downloaded AppImage was mode `644`; changed it to mode `755`; reproduced
  the next startup failure through the AppImage execution path with
  `libfontconfig.so.1` missing; confirmed `ldd` also reports
  `libfontconfig.so.1` and `libfreetype.so.6` as unresolved from the extracted
  AppImage. Added a focused Flutter test that fails until Linux AppImage builds
  collect runtime loader libraries and the AppRun smoke checks unresolved
  dependencies. Implemented AppDir ELF dependency collection in
  `scripts/build_linux_release.zsh`, added `LD_LIBRARY_PATH` setup in AppRun,
  and added an `ldd` unresolved-library check to
  `scripts/smoke_linux_appimage_apprun_env.zsh`. Added a release workflow
  `verify` job that runs `just verify`; `publish` now waits for `verify`,
  `linux`, and `macos` jobs before uploading GitHub Release assets. Updated
  release documentation to record that publishing is gated on release workflow
  verification.
- Remaining work: rerun local verification after the release workflow change,
  commit and push to `main`, move the `v1.0.3` tag to the fixed commit, and wait
  for the tag-triggered GitHub Actions release workflow to finish successfully.
- Next action: run local governance and verification gates.
- Verification: focused
  `flutter test test/linux_window_chrome_test.dart --plain-name "Linux AppImage
  bundles runtime loader libraries"` failed before the implementation because
  the expected build/smoke coverage was absent, then passed after the change.
  `zsh -n scripts/build_linux_release.zsh
  scripts/smoke_linux_appimage_apprun_env.zsh`; `flutter test
  test/linux_window_chrome_test.dart`; `just linux-release-check` passed and
  produced
  `.dart_tool/konyak/release/linux/Konyak-1.0.3-linux-x86_64.AppImage` at
  38,544,576 bytes with bundled `libfontconfig.so.1` and `libfreetype.so.6`;
  direct AppImage CLI execution with `--konyak-cli list-runtimes --json`
  reached the CLI and returned schema version 1 after filtering the NixOS
  `appimage-run` status line; `just verify-governance`; `just verify-safety`;
  `just format-check`; `just lint`.
