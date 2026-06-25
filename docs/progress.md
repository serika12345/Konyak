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

- Timestamp: 2026-06-25 19:58 JST
- State: `completed`
- Branch: `main`
- Active work: fixing Konyak close behavior for Wine process termination.
- Related TODO: none; user-reported process lifecycle defect.
- Purpose: make the close-time Wine process termination setting reliable and
  change its default to off.
- Completed work: static inspection found that close-time termination was
  launched with an unawaited Flutter CLI call; added failing coverage for the
  default-off setting, macOS terminate-before-quit wait path, and native
  terminate hook; changed Flutter and CLI setting defaults to off; added a
  macOS `applicationShouldTerminate` bridge that waits for the Flutter
  `terminateWineProcessesBeforeQuit` handler before allowing app termination.
- Remaining work: none for this fix. Sub-agent isolation was not available for
  this turn because delegation tools require an explicit user request;
  investigation, implementation, and audit were kept separate in this handoff.
- Next action: commit the fix if requested.
- Verification: failing focused tests reproduced the old behavior for
  `get-app-settings --json defaults Wine close termination off`, `macOS
  terminate request waits for Wine process termination before replying`, and
  `macOS app waits for Flutter close cleanup before terminating`; after the fix,
  those focused tests passed, along with `enabled close behavior terminates Wine
  processes on dispose` and `loads and sets system appearance through the app
  settings contract`. Full verification passed with `just verify-governance`,
  `just verify-safety`, `just flutter-format-check`, `just swift-lint`, `just
  flutter-analyze`, `just flutter-test`, `just cli-test`, `just format-check`,
  and `just lint`.
