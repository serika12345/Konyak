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

- Timestamp: 2026-06-25 19:18 JST
- State: `completed`
- Branch: `main`
- Active work: migrating Konyak localization strings to ARB-backed generation.
- Related TODO: none; user-requested Flutter/CLI settings feature.
- Purpose: replace the manual in-code localization map with Flutter
  `gen-l10n` ARB files and generated typed localization APIs.
- Completed work: added English/Japanese ARB files, `l10n.yaml`,
  generated `KonyakLocalizations`, System Default/English/Japanese locale
  wiring, typed UI call sites, ARB resource tests, and the refreshed settings
  dialog language golden at
  `apps/konyak/test/goldens/app_settings_dialog_language.png`.
- Remaining work: none for this migration.
- Next action: choose the next open item from `docs/todo.md`.
- Verification: `cd apps/konyak && flutter gen-l10n`; `cd apps/konyak &&
  flutter test test/app/localization_resources_test.dart
  test/app/app_settings_runtime_view_model_test.dart`; `cd apps/konyak &&
  flutter test test/widget_test.dart --plain-name "settings dialog language
  selector matches golden" --update-goldens`; `cd apps/konyak && flutter test
  test/widget_test.dart --plain-name "settings dialog language selector matches
  golden"`; `just flutter-format-check`; `just flutter-analyze`; `just
  flutter-test`; `just verify-governance`; `just verify-safety`; `just
  format-check`; `just lint` all passed.
