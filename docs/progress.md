# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-18 23:06 JST
- State: `completed`
- Related work: GitHub issue `#64`; branch
  `feature/64-user-profile-management`; base commit `ec5c020`; verified P1/P2
  commits `9b1bc00` and `4079527`; P3 commit `9864876`; draft pull request
  `#65`.
- Purpose: implement editable, importable, exportable, and deletable
  user-owned compatibility profiles while keeping bundled profiles immutable
  and applied bottle behavior deterministic; address draft PR review feedback
  so profile actions do not close and recreate Profile Manager, and keep their
  completion feedback above the modal route; prevent invalid manifest edits
  from leaving the editor or enabling Save.
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
  - review found that import, export, duplicate/edit, and delete currently pop
    Profile Manager before running and recreate it afterward, which loses
    transient dialog state and causes visible flicker
  - moved import/export file selection into the mounted dialog and routed
    confirmed library actions through an injected sealed callback contract
  - successful import, duplicate, edit, and delete operations now replace only
    the dialog's immutable catalog snapshot and selection; export keeps the
    existing snapshot, and all actions preserve the program-path field
  - picker, manifest-editor, and delete-confirmation cancellation now return
    without executing an action, reloading the catalog, showing feedback, or
    changing visible dialog state
  - review found that action completion snackbars are still owned by the home
    Scaffold and therefore render behind the mounted Profile Manager route
  - added explicit action-feedback variants to the dialog callback result and
    removed profile library notifications from the home Scaffold boundary
  - Profile Manager now owns a transparent Scaffold and ScaffoldMessenger, so
    success and failure snackbars render on the modal route while catalog and
    cancellation behavior remain unchanged
  - review found that the manifest editor enables Save for any non-empty text
    and closes before CLI validation or persistence completes
  - added a temporary-manifest Flutter CLI boundary that runs the canonical
    `validate-install-profile --json` contract without persisting the edit
  - the manifest editor now disables Save immediately after every change and
    enables it only after debounced CLI schema and semantic validation succeeds
  - invalid edits preserve the current JSON and show the CLI diagnostic inline;
    changing a user profile id is also rejected before update
  - edit and duplicate persistence now run while the editor remains mounted;
    rejected actions preserve the editor and input, while completed actions
    close it and apply the returned catalog snapshot to Profile Manager
  - extracted the manifest editor into a focused dialog module to keep Profile
    Manager below the governance line limit and recorded its state contract in
    the Flutter architecture plan
  - CI reproduced an architecture-gate failure because temporary manifest
    filesystem I/O still lives directly in `konyak_cli_program_commands.dart`
  - moved temporary manifest creation, UTF-8 writing, cleanup, and filesystem
    failure capture into a typed app I/O service with explicit sealed results
  - the CLI command adapter now consumes that service without importing
    `dart:io`; validation, import, and update retain their existing argv and
    structured failure contracts
  - temporary-manifest client tests now also prove the staged file is deleted
    after the CLI command completes
  - CI passed the repaired architecture gate, then exposed a Linux golden
    mismatch in the delete-feedback SnackBar: 521 Flutter tests passed and the
    remaining golden differed by 1.09 percent
  - traced the cross-platform mismatch to SnackBar content inheriting the
    Flutter test-only Ahem font instead of Konyak's bundled Inter family
  - made SnackBar content use Inter and the same Japanese fallback chain as the
    application theme; the refreshed golden now renders the deletion message
    as text while retaining the existing one-percent comparison threshold
- Remaining work:
  - no implementation remains in the CI architecture or golden repair scope
  - review and merge draft pull request `#65`; repository sharing remains a
    separately deferred roadmap item
- Next action: confirm the next draft pull request `#65` CI run before merge.
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
  - the focused import regression failed before the review fix because the
    program-path field became empty after dialog recreation, then passed after
    the action lifecycle change
  - all eight focused Profile Manager widget/golden tests pass, including
    successful in-place export/duplicate/delete and cancellation-state checks
  - focused golden capture passed again with
    `flutter test --update-goldens test/widget_test.dart --plain-name
    "Profile Manager automatic install action matches golden"`; the existing
    artifact remains unchanged
  - review-fix final gates pass: `just verify-governance`,
    `just verify-safety`, `just format-check`, `just lint`, `just cli-test`
    (571 tests), and `just flutter-test` (519 tests)
  - the delete-feedback regression failed before implementation because its
    text had no Profile Manager ancestor, then passed after moving feedback to
    the dialog-owned ScaffoldMessenger
  - the nine focused Profile Manager tests pass; new golden capture passed with
    `flutter test --update-goldens test/widget_test.dart --plain-name
    "Profile Manager shows delete feedback above the dialog"`; artifact:
    `apps/konyak/test/goldens/profile_manager_delete_feedback.png`
  - snackbar-layering final gates pass: `just verify-governance`,
    `just verify-safety`, `just format-check`, `just lint`, `just cli-test`
    (571 tests), and `just flutter-test` (520 tests)
  - the invalid-edit regression failed before implementation because Save
    remained enabled for `{`, then passed after CLI-backed validation was added
  - focused tests pass for invalid Save disablement, temporary manifest argv and
    contents, rejected-action editor preservation, and success-only close
  - golden capture passed with
    `flutter test --update-goldens test/widget_test.dart --plain-name
    "Profile Manager edits and deletes only user profiles"`; artifact:
    `apps/konyak/test/goldens/profile_manifest_editor_invalid.png`
  - invalid-editor final gates pass: `just verify-governance`,
    `just verify-safety`, `just format-check`, `just lint`,
    `just flutter-format-check`, `just flutter-analyze`, `just cli-test`
    (571 tests), and `just flutter-test` (522 tests)
  - both Konyak Verify runs for `43d9832` failed at
    `just verify-architecture`, which was reproduced locally before the repair
  - after moving filesystem access to the explicit I/O service,
    `just verify-architecture` passes with the new file tracked and the exact CI
    command `just verify` passes, including Flutter 522 tests and CLI 571 tests
  - refreshed the delete-feedback golden with
    `flutter test --update-goldens test/widget_test.dart --plain-name
    "Profile Manager shows delete feedback above the dialog"` and visually
    confirmed the SnackBar now renders `Deleted user-synthetic`
  - the exact CI command `just verify` passes again after the deterministic
    SnackBar typography change, including Flutter 522 and CLI 571 tests
- Remaining risk: profile authoring is intentionally a canonical JSON editor,
  so schema-sensitive authoring remains less approachable than a future typed
  form; invalid input is now rejected inline before Save using CLI diagnostics.
