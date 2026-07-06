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

- Timestamp: 2026-07-06 16:53 JST
- State: `paused`
- Branch: `task/gptk-version-import-contract`
- Active work: `G2-P1 GPTK Version Parser and Request Model`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G2-P1 GPTK Version Parser and Request Model`.
- Pull request: https://github.com/serika12345/Konyak/pull/35
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`.
- Purpose: make GPTK/D3DMetal import requests version-aware before accepting
  GPTK4 payload variants, while preserving the existing unversioned
  `install-gptk-wine --from <path> --json` command as backward-compatible
  `auto` behavior.
- Completed work: created branch `task/gptk-version-import-contract`; added
  failing parser coverage for omitted `--gptk-version`, explicit `auto`, `3`,
  `4`, and invalid values; added `GptkWineImportVersion` and
  `GptkWineInstallRequest.requestedVersion`; wired the parser and handler path
  so the requested version reaches `GptkWineInstaller`; updated CLI usage text.
- Remaining work: review and merge PR #35 before starting G2-P2.
- Next action: review PR #35. If no changes are requested, merge it, then
  continue to G2-P2 for payload-version detection and mismatch diagnostics.
- Verification so far: `nix develop -c zsh -lc 'cd packages/konyak_cli && dart
  test test/cli_parser_boundary_options_test.dart --plain-name "runtime parser
  options"'` passed; `nix develop -c zsh -lc 'cd packages/konyak_cli && dart
  test test/cli_contract_runtime_install_test.dart --plain-name
  "install-gptk-wine forwards the requested GPTK version"'` passed; `nix
  develop -c zsh -lc 'just cli-test && just verify-governance && just
  verify-safety && just format-check && just lint'` passed.
