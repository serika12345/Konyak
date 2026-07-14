# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 18:53 JST
- State: `paused`
- Branch: `fix/profile-dependencies-before-installer`; based on the `main`
  merge of PR #51 (`9ed1730`) and carrying the dependency-order fix originally
  committed as `2105572`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: correct the public profile-install CLI so every declared winetricks
  dependency completes in manifest order before the Windows installer starts,
  before exposing automatic installation through Profile Manager.
- Completed work:
  - merged PR #50, which added the bounded installer-resource manifest and read
    contracts
  - merged PR #51, which added the typed public `install-program-profile` CLI,
    resource verification, installer/dependency execution, managed-program
    verification, and binding persistence
  - changed the orchestrator to fetch and verify the installer first, run every
    declared dependency, release the staged payload on dependency failure, and
    start the installer only after all dependencies succeed
  - prevented installer launch, managed-program verification, and persistence
    after dependency startup or non-zero-exit failures
  - preserved typed dependency index and verb context in progress and failure
    results
  - updated the roadmap and public-CLI tests to require dependency-first order
- Remaining work:
  - review and merge the focused dependency-order pull request
  - submit the Profile Manager automatic-install GUI path as a later pull
    request only after the order fix is on `main`
  - continue the remaining profile recovery, runtime, Steam dependency,
    completion-policy, pin-icon, native-component, and E2E-gate commits one pull
    request at a time
- Next action: merge the dependency-order pull request, then cherry-pick
  `aa90256` onto the resulting `main` for the Profile Manager GUI pull request.
- Verification performed:
  - the original TDD run dynamically confirmed the incorrect baseline request
    order was installer, `corefonts`, then `vcrun2022`
  - focused orchestration and public-command tests prove the corrected request
    order is `corefonts`, `vcrun2022`, installer
  - dependency failure cases issue no installer request, make no verifier or
    persistence call, release the fetched resource once, and retain typed
    failure context
  - the current cherry-picked branch passed `just verify-governance`, `just
    verify-safety`, `just format-check`, `just lint`, `just cli-format-check`,
    `just cli-analyze`, `just cli-test` (488 tests), and `git diff --check`
- Remaining risk:
  - the maintained real network/Wine public-CLI smoke remains deferred to the
    later synthetic E2E-gate pull request; this focused change is covered by
    deterministic orchestration and CLI contract tests
