# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-16 21:13 JST
- State: `in_progress`
- Related release: planned Konyak `v1.1.1+11`; issues `#62` and pull request
  `#63`; branch `main`; local HEAD `65b3600`; `origin/main` at `a1dddd9`.
  Neither the `v1.1.1` tag nor GitHub release exists yet.
- Purpose: prepare and verify the v1.1.1 patch release containing the program
  working-directory contract and the pinned-program selection correction,
  then publish and independently audit the release artifacts.
- Completed work:
  - merged pull request `#63` at `a1dddd9`; its hosted CI passed, including the
    maintained macOS and Linux public-runtime CLI smoke paths
  - dynamically proved the executable-parent default and validated bottle-local
    custom `C:\\` working-directory contracts through Konyak's public macOS CLI
    path; both default and custom probes read relative data and exited 0
  - applied the shared CWD contract to regular, pinned, and resolved-shortcut
    launches, including explicit rejection before runner or pre-launch side
    effects when the working directory cannot be resolved
  - committed the pinned-program tile selection correction locally as
    `65b3600`, so selecting another tile clears the previous accumulated
    selection feedback without changing launch or context-menu behavior
  - prepared the v1.1.1 release-note draft at
    `.dart_tool/konyak/release-notes.md`
- Remaining work:
  - push local `main` commit `65b3600` and confirm its hosted CI succeeds
  - set the release candidate to `v1.1.1+11` and run the complete
    `just release-candidate-gates` contract
  - create and push the verified release commit and `v1.1.1` tag, then allow
    `.github/workflows/publish.yml` to build, smoke, and publish the release
  - independently audit the published macOS DMG, Linux AppImage, release
    metadata, and SHA-256 checksums
- Next action: push `main` at `65b3600`, wait for its hosted CI, then prepare
  `v1.1.1+11` and run the full release-candidate gates before creating a tag.
- Verification performed:
  - pull request `#63` hosted CI passed, including the macOS and Linux public
    runtime smoke jobs for regular, pinned, and resolved-shortcut CWD behavior
  - two independent public-CLI macOS Wine runs proved relative-data access for
    executable-parent and custom CWDs; evidence is under
    `.dart_tool/konyak/program-cwd-probe-proof-20260716-104650/logs` and
    `.dart_tool/konyak/program-cwd-probe-audit-20260716/logs`
  - focused regression test failed before the fix and passed after it
  - focused pinned-program suite passed (9 tests)
  - `just flutter-test` passed (509 tests)
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just flutter-format-check`, `just flutter-analyze`, and
    `git diff --check` passed
  - the full v1.1.1 `just release-candidate-gates` run and the release
    `publish.yml` workflow have not run yet and are not recorded as successful
- Remaining risk:
  - macOS release artifacts remain ad-hoc signed and unnotarized
  - the original Touhou executable has not been rerun after the fix; the
    synthetic Windows probe dynamically proves the same relative-data contract
  - final release artifacts do not exist and cannot be audited until the
    candidate gates, release tag, and publish workflow succeed
