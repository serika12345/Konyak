# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-17 22:25 JST
- State: `in_progress`
- Related work: GitHub issue `#64`; branch
  `feature/64-user-profile-management`; base commit `ec5c020`.
- Purpose: implement editable, importable, exportable, and deletable
  user-owned compatibility profiles while keeping bundled profiles immutable
  and applied bottle behavior deterministic.
- Completed work:
  - inspected the current manifest schema, built-in-only catalog, CLI JSON
    projections, Profile Manager flow, and bottle binding behavior
  - documented the design and opened GitHub issue `#64` with explicit behavior,
    security, CLI, UI, and verification acceptance criteria
  - split the work into P1 binding snapshots, P2 manifest/provider/CLI support,
    and P3 Profile Manager UI under one PR gate
  - completed P1: newly applied and repaired bindings now persist the validated
    run completion policy and complete compatibility rule set and consume that
    snapshot without depending on a mutable catalog entry
  - preserved legacy bottle compatibility by using catalog lookup only for old
    bindings that do not contain the new optional launch-policy snapshot
  - completed P2: added one canonical JSON manifest validation and
    serialization path, merged immutable bundled profiles with Konyak-managed
    user profiles, and isolated invalid user manifests as catalog diagnostics
  - added versioned JSON CLI contracts for validation, import, digest-guarded
    update, export, and user-only deletion; built-in shadowing and mutation are
    rejected and writes use atomic replacement
- Remaining work:
  - add Flutter client models for the profile mutation contracts
  - add Profile Manager source visibility, import, edit/duplicate, export, and
    user-only deletion with focused widget and golden coverage
  - run all required verification and open the draft pull request
- Next action: start P3 with failing Flutter parser, client, widget, and golden
  tests, then connect the Profile Manager operations to the CLI contracts.
- Verification performed:
  - the focused snapshot regression test failed before implementation and
    passed after implementation
  - focused metadata persistence and full profile rule tests passed
  - `just cli-test` passed with 562 tests
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, and `git diff --check` passed
  - P2 I/O and CLI contract tests failed before implementation and pass after
    implementation; `just cli-test` now passes with 570 tests
- Remaining risk: the Flutter client and Profile Manager do not yet expose the
  new profile mutation contracts; direct JSON editing also needs clear
  validation feedback before the feature is ready for users.
