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

- Timestamp: 2026-06-27 12:21 JST
- State: `completed`
- Branch: `main`
- Active work: adding expandable one-time launch options to the Run program
  dialog.
- Related TODO: none; user-requested Flutter/CLI run workflow improvement.
- Purpose: let ad hoc `Run` launches specify arguments and environment
  variables using the same setting shape as pinned program configuration,
  without changing default run behavior.
- Completed work: added failing tests for the Run dialog expanded options, the
  Flutter CLI client `run-program` arguments, and the CLI `run-program`
  contract; implemented `RunProgramDialogResult`, reusable environment editor
  key prefixes, one-time `--settings-json` forwarding, and CLI-side merging of
  saved program settings with one-time run settings.
- Remaining work: none for this Run dialog one-time launch options change.
- Next action: none.
- Verification: focused tests passed after implementation:
  `flutter test test/widget_test.dart --plain-name "run program dialog shows
  expandable launch options"`; `flutter test test/widget_test.dart
  --plain-name "run program dialog sends one-time arguments and environment"`;
  `flutter test test/cli/konyak_cli_client_test.dart --plain-name "passes
  one-time program settings to run-program"`; `dart test
  test/cli_contract_test.dart --plain-name "run-program --json applies one-time
  program settings"`. Golden screenshot generated at
  `apps/konyak/test/goldens/run_program_dialog_options.png`. Required gates
  passed: `just verify-governance`; `just verify-safety`; `just format-check`;
  `just lint`; `just flutter-test`; `just cli-test`.
