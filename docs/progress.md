# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-12 14:24 JST
- State: `planned`
- Branch: `task/steam-profile-install-ui`; latest committed code change is
  `0646893`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: let users author, validate, import, export, install, and share
  declarative compatibility profiles without adding application-specific app or
  runtime branches.
- Completed work: none for this planned milestone.
- Remaining work:
  - define user profile storage, source identity, digest, and conflict policy
  - add shared validation plus CLI import/export operations
  - add Profile Manager editing, import, and export UI
  - define immutable installer resources and a generic install operation that
    runs declared winetricks dependencies only during profile installation
  - preserve `apply-program-profile` as a side-effect-free manual binding path
- Next action: specify the persisted user-profile repository and canonical
  import/export contract, then add failing CLI contract tests.
- Verification performed: deliberately not started for this planned milestone.
