# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-17 23:06 JST
- State: `completed`
- Related work: GitHub issue `#64`; branch
  `feature/64-user-profile-management`; base commit `ec5c020`; verified P1/P2
  commits `9b1bc00` and `4079527`; P3 commit `9864876`; draft pull request
  `#65`.
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
  - completed P3: Flutter validates the new versioned mutation responses,
    chooses manifest files through an injected file boundary, and sends argv
    commands through the existing CLI client
  - extended Profile Manager with source visibility, import, canonical JSON
    edit, built-in duplication, export, user-only confirmed deletion, localized
    progress/result feedback, and automatic catalog reload
  - extracted the canonical manifest codec and install-progress parser into
    focused modules to stay within governance line limits
  - recorded the durable bundled/user provider, optimistic digest, validation,
    and applied-policy snapshot decisions in the architecture plan
- Remaining work:
  - no implementation remains in issue `#64` scope
  - review and merge the draft pull request; repository sharing remains a
    separately deferred roadmap item
- Next action: review the draft pull request and its updated Profile Manager
  golden before merge.
- Verification performed:
  - the focused snapshot regression test failed before implementation and
    passed after implementation
  - focused metadata persistence and full profile rule tests passed
  - `just cli-test` passed with 562 tests
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, and `git diff --check` passed
  - P2 I/O and CLI contract tests failed before implementation and pass after
    implementation; `just cli-test` now passes with 570 tests
  - P3 parser, client, widget, localization, and golden tests failed before
    their implementations and now pass
  - focused golden capture passed with
    `flutter test --update-goldens test/widget_test.dart --plain-name
    "Profile Manager automatic install action matches golden"`; artifact:
    `apps/konyak/test/goldens/profile_manager_automatic_install.png`
  - `just cli-test` passes with 571 tests and `just flutter-test` passes with
    517 tests
  - the final matrix passed: `just verify-governance`, `just verify-safety`,
    `just format-check`, `just lint`, `just cli-test` (571 tests), and
    `just flutter-test` (517 tests)
- Remaining risk: profile authoring is intentionally a canonical JSON editor,
  so schema-sensitive authoring remains less approachable than a future typed
  form; invalid input is rejected by the CLI with structured field diagnostics.
