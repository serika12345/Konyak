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

- Timestamp: 2026-07-06 22:43 JST
- State: `completed`
- Branch: `main`
- Active work: Show the installed GPTK/D3DMetal version and surface GPTK
  manual-version mismatch import failures in Settings.
- Related TODO: `docs/todo.md` now points at the next DLSS/MetalFX
  rendering-proof task.
- Pull request: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/5 merged as
  `0a09716b`; parent PR https://github.com/serika12345/Konyak/pull/39
  merged as `104e23b`; parent PR https://github.com/serika12345/Konyak/pull/40
  merged as `54f66d4`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`; parent PR https://github.com/serika12345/Konyak/pull/36
  merged as `4e56d49`; parent PR https://github.com/serika12345/Konyak/pull/37
  merged as `2445a0d`; runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/4 merged as
  `472091f`; parent PR https://github.com/serika12345/Konyak/pull/38 merged
  as `3e1d5f`.
- Runtime branch: no runtime submodule changes planned; parent `main` records
  runtime submodule commit `61624ad`.
- Purpose: make the Settings runtime panel and `list-runtimes --json` surface
  the installed GPTK/D3DMetal major version, and make manual GPTK 3/4 selection
  mismatches visible next to the GPTK import controls instead of only relying
  on a generic runtime failure row.
- Workstream separation: the multi-agent tool is available, but its tool-level
  instructions allow spawning only when the user explicitly requests
  sub-agents. Investigation and audit evidence are therefore recorded here and
  in the final handoff.
- Completed work:
  - Added `list-runtimes --json` GPTK/D3DMetal major-version detection from
    the installed `D3DMetal.framework` metadata.
  - Added the Settings runtime panel row that shows the currently installed
    GPTK version as `GPTK 3`, `GPTK 4`, `Installed`, or `Not installed`.
  - Added a GPTK import failure message inside the GPTK panel, preserving the
    CLI mismatch diagnostic such as `Requested GPTK 4, but selected
    GPTK/D3DMetal payload is GPTK 3.`
  - Regenerated English and Japanese localizations.
  - Updated the Settings GPTK import golden artifact at
    `apps/konyak/test/goldens/app_settings_gptk_import_version.png`.
  - Added the Settings mismatch golden artifact at
    `apps/konyak/test/goldens/app_settings_gptk_import_version_mismatch.png`.
  - Added CLI and widget coverage for an installed GPTK4 runtime and visible
    GPTK version mismatch errors.
- Remaining work: none for this GPTK Settings display/error task.
- Next action: continue with the next TODO-backed DLSS/MetalFX rendering-proof
  task when requested.
- Verification performed:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_process_update_test.dart --plain-name "list-runtimes --json reports the installed GPTK major version"'`
    first failed with `user-provided`, then passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog shows installed GPTK version"'`
    first failed before the UI row existed, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog shows GPTK version mismatch import errors"'`
    first failed before the GPTK-panel error message existed, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog shows GPTK version mismatch import errors" --update-goldens'`
    passed and captured
    `apps/konyak/test/goldens/app_settings_gptk_import_version_mismatch.png`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings GPTK import version panel matches golden" --update-goldens'`
    passed and captured `apps/konyak/test/goldens/app_settings_gptk_import_version.png`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings GPTK import version panel matches golden"'`
    passed against the captured golden.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_process_update_test.dart --plain-name "list-runtimes --json"'`
    passed; 12 matching tests passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart --name "install-gptk-wine rejects GPTK"'`
    passed; mismatch rejection covered both GPTK3-request/GPTK4-payload and
    GPTK4-request/GPTK3-payload.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog imports"'`
    passed; 3 matching tests passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog"'`
    passed; 8 matching tests passed.
  - `nix develop -c zsh -lc 'just cli-test'` passed; 383 tests passed.
  - `nix develop -c zsh -lc 'just flutter-format-check && just flutter-analyze && just flutter-test'`
    passed; Flutter test reported 467 tests passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
