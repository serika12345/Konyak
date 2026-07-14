# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-13 21:05 JST
- State: `paused`
- Branch: `task/profile-installer-flow`; base commit is `6f23f55`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: let users author, validate, import, export, install, and share
  declarative compatibility profiles without adding application-specific app or
  runtime branches.
- Completed work:
  - inspected the existing profile schema, domain model, CLI contracts,
    Profile Manager, winetricks planner, resource download support, persisted
    bindings, and runtime smoke boundaries
  - split the automatic profile installation work into IP-P1 through IP-P4 in
    `docs/todo.md`
  - confirmed that profile compatibility is not required before the first
    release, so IP-P1 updates the current schema directly
  - made one immutable HTTPS installer resource mandatory in profile schema 1
    and added matching JSON Schema, Dart semantic, CLI inspect, and Flutter
    parser validation
  - restricted installer resources to HTTPS URLs with a host and no userinfo or
    fragment, 64-character SHA-256 values, and safe `.exe` or `.msi` basenames
  - bounded dependency winetricks verbs and preserved their declared order
  - restricted managed program paths to absolute C-drive `.exe` paths without
    empty, dot, dot-dot, or NUL components
  - added the official Steam installer URL and a dynamically verified payload
    digest to the built-in Steam profile
  - completed an independent implementation audit and corrected its Flutter
    external-data validation finding
- Remaining work:
  - review IP-P1 and then complete IP-P2 through IP-P4
  - after the automatic installation path is stable, resume user profile
    storage, canonical import/export, editing, and sharing work
- Next action: review the IP-P1 manifest/read-contract diff. After approval,
  start IP-P2 on `task/profile-install-cli` with failing command-orchestration
  tests; do not add resource I/O to the IP-P1 branch.
- Verification performed:
  - TDD red states captured for the new CLI/domain and Flutter parser contracts
  - `just cli-format-check`, `just cli-analyze`, and `just cli-test` passed; 460
    CLI tests passed
  - `just flutter-format-check`, `just flutter-analyze`, and
    `just flutter-test` passed; 477 Flutter tests passed after the final parser
    hardening
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed
  - the Steam installer returned HTTP 200 with no redirect and 2,380,800 bytes;
    its SHA-256 matched
    `7d3654531c32d941b8cae81c4137fc542172bfa9635f169cb392f245a0a12bcb`
  - `git diff --check` passed
