# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-16 20:57 JST
- State: `completed`
- Related report: pinned-program single-click selection remains visible after a
  different pinned-program tile is clicked; branch `main`; base commit
  `a1dddd9`.
- Purpose: ensure pinned-program selection feedback belongs to one active tile
  instead of accumulating independently on every tile that has been clicked.
- Completed work:
  - synchronized local `main` with merged pull request `#63`
  - inspected the public bottle overview and pinned-program tile path
  - identified that each stateful tile owns an `_isSelected` flag that is set
    to true on pointer down and is never cleared by selection of another tile
  - added a Widget regression test that clicks two pinned programs in sequence
    and asserts that only the latest tile retains its selection background
  - confirmed the test failed before the fix because both tiles retained the
    selected background
  - wrapped each tile in an independent `TapRegion` so an outside pointer down
    clears the old tile while preserving its existing launch, bounce, and
    context-menu handlers
  - confirmed the focused pinned-program regression suite and the full Flutter
    suite pass after the fix
- Remaining work: none for the requested selection-feedback correction.
- Next action: review the committed change, then push or open a pull request if
  desired.
- Verification performed:
  - focused regression test failed before the fix and passed after it
  - focused pinned-program suite passed (9 tests)
  - `just flutter-test` passed (509 tests)
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just flutter-format-check`, `just flutter-analyze`, and
    `git diff --check` passed
- Remaining risk: native macOS pointer input was not manually exercised; the
  Widget test dynamically covers two sequential clicks through the public
  Konyak UI and the existing double-click/context-menu tests remain green.
