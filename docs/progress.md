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

- Timestamp: 2026-06-25 18:37 JST
- State: `completed`
- Branch: `main`
- Active work: implementing the first Konyak i18n pass with Japanese support.
- Related TODO: none; user-requested Flutter/CLI settings feature.
- Purpose: add a persisted language preference with System Default, English,
  and Japanese choices, and localize the current Flutter UI to Japanese first.
- Completed work: added the app/CLI language setting contract, wired Flutter
  locale selection through `MaterialApp`, added Japanese localization strings,
  localized the current app surfaces, added a bundled Noto Sans JP font for CJK
  rendering, fixed golden font loading to avoid cross-test cached futures, and
  added focused CLI, Flutter client, widget, and golden coverage.
- Remaining work: none for this i18n pass.
- Next action: choose the next open item from `docs/todo.md`.
- Verification: passed `just verify-governance`, `just verify-safety`,
  `just format-check`, `just lint`, `just flutter-format-check`,
  `just flutter-analyze`, `just flutter-test`, and `just cli-test`; regenerated
  and visually checked
  `apps/konyak/test/goldens/app_settings_dialog_language.png`.
