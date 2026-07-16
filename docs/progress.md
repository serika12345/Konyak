# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-16 10:55 JST
- State: `completed`
- Related issue: `#62`; pull request `#63`; branch
  `fix/program-working-directory`; implementation commit `08a869e`; base commit
  `71c3873`.
- Purpose: make normal Windows program launches use the executable's parent
  directory as their default current working directory, with a validated
  per-program override shared by normal, pinned, and shortcut launch paths.
- Completed work:
  - dynamically confirmed the failing Touhou process used the hosted runtime
    directory as its CWD and then failed to load relative `data/...` assets
  - confirmed Japanese locale settings fixed text rendering independently of
    the remaining relative-file failure
  - compared CrossOver 26.1, whose Run Command path supplies an explicit
    executable-parent `--workdir` and whose launcher recipes can override it
  - filed GitHub issue `#62` with the evidence and intended contract
  - made regular macOS and Linux program requests resolve the executable parent
    as their default CWD while preserving maintenance-command CWD contracts
  - added a persisted, bottle-portable custom `C:\` CWD setting with external
    input validation, existence checks, explicit JSON errors, and default reset
  - applied the shared resolution contract to normal, pinned, and resolved
    shortcut launches, including rejection of unresolvable program paths before
    runner or pre-launch side effects
  - added the Flutter program-settings and one-time-run controls, English and
    Japanese localization, input validation, and two updated golden images
  - added a Windows relative-data probe and macOS/Linux public-CLI runtime smoke
    coverage; both corresponding Actions watch and execute the maintained paths
  - proved the final macOS contract through the public CLI at 2026-07-16
    10:46:50 JST: fresh-bottle default and custom CWD runs both read relative
    data and exited 0; evidence is under
    `.dart_tool/konyak/program-cwd-probe-proof-20260716-104650/logs`
  - completed an independent post-fix audit, including a second public-CLI Wine
    run under `.dart_tool/konyak/program-cwd-probe-audit-20260716/logs`
- Remaining work:
  - none for implementation and pull-request submission
- Next action: review the Actions results and merge pull request `#63` after
  approval.
- Verification performed:
  - `just cli-test` (562 tests), `just flutter-test` (508 tests)
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, and `git diff --check`
  - CWD probe build as PE32+ x86-64, shell syntax checks for all three affected
    scripts, and two independent public-CLI macOS Wine dynamic runs
- Remaining risk: the Linux runtime smoke and the original Touhou executable
  were not launched locally after the fix; the PR Actions exercise the same
  Linux/macOS maintained smoke scripts, while the synthetic Wine probe confirms
  the relative-data contract independently of the game.
