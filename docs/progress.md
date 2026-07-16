# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-16 21:33 JST
- State: `in_progress`
- Related release: Konyak `v1.1.1+11`; issues `#62` and pull request `#63`;
  branch `main`; release commit `bdd8c0c`; pushed tag `v1.1.1`; initial publish
  workflow run `29498350589`. No GitHub Release exists.
- Purpose: correct the stale v1.1.1 verification note found by independent
  audit, rerun the full release contract on the final revision, replace the tag,
  publish, and independently audit the resulting artifacts.
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
  - ran the complete local `just release-candidate-gates` contract successfully
    for `v1.1.1+11`: 509 Flutter tests, 562 CLI tests, macOS DMG build, runtime
    extraction, DMG layout, PuTTY Finder launch, CLI bridge, and update handoff
    all passed
  - created release commit `bdd8c0c`, created and pushed tag `v1.1.1`, and
    pushed `main`; local HEAD and `origin/main` both reached `bdd8c0c`
  - independently audited the release state and found that both release-note
    copies still incorrectly claimed the local candidate gates had not run
  - intentionally cancelled initial publish workflow run `29498350589` before
    it could create a GitHub Release
  - confirmed no GitHub Release exists, confirmed the worktree was clean before
    this corrective edit, and removed the temporary `custom_lint.log`
- Remaining work:
  - commit the corrected tracked release note and progress snapshot
  - rerun the full `just release-candidate-gates` contract on the final release
    revision
  - push the correction and confirm the resulting `main` hosted CI succeeds
  - move or recreate `v1.1.1` on the final verified release commit and start a
    new publish workflow run
  - require the tagged workflow's verify, Linux, and macOS jobs to pass before
    its publish job creates the GitHub Release
  - independently audit the published macOS DMG, Linux AppImage, release
    metadata, and SHA-256 checksums
- Next action: commit the stale-note correction, run full candidate gates on
  that final revision, push it, and wait for `main` CI before replacing the tag
  and starting a new publish run.
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
  - the complete local v1.1.1 release-candidate gates passed for `v1.1.1+11`,
    including the macOS package and release smoke paths listed above
  - initial publish run `29498350589` was cancelled before Release creation and
    is not recorded as a successful final publication
- Remaining risk:
  - macOS release artifacts remain ad-hoc signed and unnotarized
  - the original Touhou executable has not been rerun after the fix; the
    synthetic Windows probe dynamically proves the same relative-data contract
  - the pushed `v1.1.1` tag still identifies the stale-note release commit until
    it is replaced after final verification
  - final release artifacts do not exist and cannot be audited until the new
    tagged publish workflow succeeds
