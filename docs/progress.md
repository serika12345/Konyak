# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 19:00 JST
- State: `paused`
- Branch: `task/profile-manager-auto-install`; based on the `main` merge of PR
  #52 (`5950bea`) and carrying the GUI implementation originally committed as
  `aa90256`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: expose the verified public `install-program-profile` CLI through
  Profile Manager without reproducing installation orchestration in Flutter.
- Completed work:
  - merged PRs #50 through #52 for installer-resource declarations, the public
    profile-install CLI, and dependency-before-installer ordering
  - added a Flutter contract for the versioned profile-install JSONL stream,
    with typed stages, dependency context, states, and invalid-record handling
  - added streamed `install-program-profile` execution to the Flutter CLI client
    with explicit success and failure results
  - made Profile Manager show profile source, manifest SHA-256, installer URL
    and SHA-256, and numbered winetricks dependency order before execution
  - added visibly separate automatic-install and manual-apply decisions
  - made automatic installation render CLI stage progress and reload the bottle
    only after the CLI reports success
  - retained the manual apply path without downloading or executing resources
  - added parser, client, widget, and golden coverage for the complete GUI flow
  - removed the completed Profile Manager milestone and implementation gate from
    `docs/todo.md`
- Remaining work:
  - review and merge the focused Profile Manager pull request
  - continue the invalid-bottle recovery, runtime, Steam dependency,
    completion-policy, pin-icon, native-component, and E2E-gate commits one pull
    request at a time
- Next action: merge the Profile Manager pull request, then cherry-pick
  `3d68718` onto the resulting `main` for invalid-bottle metadata recovery.
- Verification performed:
  - the original TDD run captured the parser/client and widget red states before
    the implementation
  - targeted progress parser/client tests, automatic-install widget flow,
    retained manual-apply widget flow, and the new golden passed on the source
    branch
  - the source golden was visually inspected at 1040x720; source identity,
    manifest digest, installer URL and digest, dependency order, progress, and
    both actions are visible
  - the current cherry-picked branch passed the focused golden update test,
    `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`
    (484 tests), `just verify-governance`, `just verify-safety`, `just
    format-check`, `just lint`, and `git diff --check`
  - the regenerated 1040x720 golden was unchanged and has SHA-256
    `11822bbdae2543e7182252ffb72a44e140f49128ad73a8dc14287457bf068877`
- Remaining risk:
  - this split PR verifies the UI contract and rendering deterministically but
    does not rerun the real network/Wine installation; that path remains covered
    by the previously completed GUI checkpoint and the later maintained
    synthetic public-CLI E2E gate
