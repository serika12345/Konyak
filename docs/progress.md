# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-16 22:10 JST
- State: `completed`
- Related release: Konyak `v1.1.1+11`; issues `#62` and pull request `#63`;
  branch `main`; final release and tag target
  `27a725a71e331e289b4efb6aa581f9d23226fea6`; publish workflow run
  `29499806808`; [GitHub Release](https://github.com/serika12345/Konyak/releases/tag/v1.1.1).
- Purpose: publish the verified v1.1.1 program working-directory and
  pinned-program selection fixes, then independently audit the public release
  metadata and artifacts.
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
  - initially created release commit `bdd8c0c` and tag `v1.1.1`, then found
    through independent audit that both release-note copies still incorrectly
    claimed the local candidate gates had not run
  - intentionally cancelled initial publish workflow run `29498350589` before
    it could create a GitHub Release, corrected the notes, and retargeted the
    release and tag to `27a725a71e331e289b4efb6aa581f9d23226fea6`
  - completed publish workflow run `29499806808` with all four jobs successful
    and published a latest, non-draft, non-prerelease GitHub Release containing
    10 assets
  - independently audited the public release, artifact metadata, checksums,
    package layouts, embedded versions, signatures, and runtime contents
- Remaining work: none for the v1.1.1 release.
- Next action: select the next coherent work item from `docs/todo.md`.
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
  - final publish workflow run `29499806808` passed all four jobs and created
    the release only after its verify, Linux, and macOS dependencies succeeded
  - the published DMG SHA-256 is
    `0bdddf96a940d90951e76aa148e170dd8312abba19d47206eed957a79560e7e2`;
    its app reports CFBundle version `1.1.1 (11)`, passes ad-hoc deep-strict
    codesign verification, and has the expected release layout
  - the published AppImage SHA-256 is
    `2e2de7f01845cdf71faf186a886c1848212f3982b24d04c699df2ba90fe4ac08`;
    it embeds app version `1.1.1+11`, CLI version `1.1.1`, and the expected
    runtime signature
  - independent release inspection confirmed 10 public assets and
    `latest=true`, `draft=false`, and `prerelease=false`
- Remaining risk:
  - macOS release artifacts remain ad-hoc signed and unnotarized
  - the original Touhou executable has not been rerun after the fix; the
    synthetic Windows probe dynamically proves the same relative-data contract
  - GitHub Actions reports Node 20 action deprecation warnings
  - the `just prepare-release` wrapper splits whitespace-containing `--gate`
    arguments; this is a non-blocking follow-up because the release used the
    verified gate commands directly
