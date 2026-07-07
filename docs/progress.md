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

- Timestamp: 2026-07-07 11:03 JST
- State: `completed`
- Branch: `codex/runtime-wine-update-ui`
- Active work: Bring Konyak Wine runtime update UI up to the Konyak app update
  flow.
- Related TODO: no long-running TODO item; this is a focused UX/completion fix
  for the existing runtime update CLI contract.
- Purpose: make runtime Releases actionable from Flutter instead of only
  surfacing a startup snackbar when `check-runtime-update` reports an
  available Konyak Wine runtime update.
- Completed work:
  - Added startup runtime update state so the UI keeps the full
    `runtimeUpdate` record returned by `check-runtime-update`.
  - Changed startup runtime update handling from snackbar-only notification to
    a confirmation dialog with `Not Now` and `Install`, matching the Konyak app
    update prompt shape.
  - Extended the existing manual `Check for Updates...` flow so a current app
    update check continues into installed managed runtime update checks.
  - Wired confirmed runtime updates to
    `install-runtime-update <runtime-id> --json` and refreshes the known runtime
    list from the returned runtime record.
  - Added English and Japanese strings plus generated localizations for runtime
    update prompts, current/unknown status, and check/install failures.
  - Added widget coverage for startup runtime update prompting, manual menu
    runtime update checks, runtime update installation, and the runtime update
    confirmation golden.
  - Generated and visually inspected
    `apps/konyak/test/goldens/konyak_wine_update_confirmation_prompt.png`.
- Remaining work: none for the local implementation; publish the verified
  branch as a draft PR.
- Next action: commit, push, and open the draft PR for review.
- Verification performed:
  - Failing tests captured before implementation:
    - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
      test/widget_test.dart --plain-name "macOS prompts before installing
      Konyak Wine runtime updates on startup"'`
    - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
      test/widget_test.dart --plain-name "macOS app menu command checks Konyak
      Wine updates"'`
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --plain-name "macOS prompts before installing Konyak
    Wine runtime updates on startup"'` passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --plain-name "macOS app menu command checks Konyak
    Wine updates"'` passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --update-goldens --plain-name "macOS Konyak Wine
    update confirmation prompt matches golden"'` passed and wrote the golden.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --plain-name "macOS Konyak Wine update confirmation
    prompt matches golden"'` passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart'` passed with 131 tests.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/app/immutability_test.dart'` passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/cli/konyak_cli_client_test.dart --plain-name "installs runtime updates
    through the JSON CLI contract"'` passed.
  - `nix develop -c zsh -lc 'just flutter-format-check &&
    just flutter-analyze && just flutter-test'` passed; Flutter test reported
    469 tests passed.
  - Initial repository common-gate run failed because
    `apps/konyak/lib/src/home_loader/home_loader_runtimes.dart` exceeded the
    governance line-count limit after adding runtime update UI. The update
    workflow was split into `home_loader_updates.dart`, reducing the original
    runtime loader file to 499 lines.
  - `nix develop -c zsh -lc 'git diff --check && git -C
    runtime/konyak-macos-runtime diff --check && just verify-governance &&
    just verify-safety && just format-check && just lint'` passed after the
    split.
