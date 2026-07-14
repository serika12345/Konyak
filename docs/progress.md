# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 20:23 JST
- State: `paused`
- Branch: `fix/profile-installer-launched-app-completion`; based on the `main`
  merge of PR #56 (`a95dcc7`) and carrying the installer-completion correction
  originally committed as `b0e6860`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system"; the next remaining installation milestone is IP-S6.
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: let automatic profile installation finish when an installer launches
  a long-lived managed application, while applying validated child-process
  rules to that first installer-launched process tree before binding persistence.
- Completed work:
  - merged PRs #50 through #56 through the Steam font and Visual C++ dependency
    profile update
  - fast-forwarded local `main` to the PR #56 merge and created this focused
    installer-completion branch
  - applied the bounded `installerCompletion.ignoreChildExecutable` profile
    capability and Steam's `steam.exe` declaration
  - applied installer-only `WINE_WAIT_CHILD_PIPE_IGNORE`, selected-profile
    child-process rules, direct-installer-exit output draining, asynchronous
    public CLI orchestration, and reserved-environment filtering
  - kept dependency execution synchronous and ordered and retained cleanup,
    managed-program verification, and binding persistence only after successful
    installer completion
  - applied schema, domain, JSON, catalog, runner, I/O, CLI, fixture, and
    contract coverage from the source correction
  - verified the completion capability, reserved-environment isolation,
    direct-exit output drain, dependency ordering, failure atomicity, and public
    streaming CLI contracts through focused and full tests
  - confirmed through the public read-only CLI that Steam exposes the typed
    child-ignore value, dependency order, and existing child-process rules with
    a digest matching the shipped profile
  - completed separate investigation and independent read-only artifact/result
    audit workstreams with no code, contract, security, or standalone-delivery
    blocker
  - removed completed IP-S5C from the remaining roadmap and aligned the delivery
    policy with the one-cherry-pick-per-PR merge gates currently in use
- Remaining work:
  - review and merge the focused pull request for this branch
  - after merge, update local `main`, create the next focused branch, and apply
    `d346ecf` for Windows-path pin icon restoration
- Next action: review and merge the pull request for this branch; do not advance
  to `d346ecf` before that merge is confirmed.
- Verification performed:
  - the source investigation dynamically reproduced the failure at 2026-07-14
    13:03-13:09 JST through the public Profile Manager path: the CLI remained
    alive after `Run Steam` because Steam descendants retained stderr, so
    managed-program verification and binding persistence were not reached
  - the same run showed installer-launched `steamwebhelper` processes lacked
    the selected child-process arguments and repeatedly lost their CEF GPU
    process, leaving a black login window
  - a read-only CrossOver 26.1 comparison at 2026-07-14 13:21-13:26 JST found
    installer-only `WINE_WAIT_CHILD_PIPE_IGNORE=steam.exe`, `--wait-children`,
    and `/dev/null` standard file descriptors
  - a later real Profile Manager checkpoint recorded that automatic dependency
    setup, installer completion with `Run Steam`, and Steam launch succeeded;
    the subsequent observed defect was limited to the fallback pin icon
  - focused model, catalog, rules, I/O, installer, and public CLI tests: 169
    passed, including a repository-owned child retaining stderr for 20 seconds
    while the requested process exits immediately; the runner preserved initial
    stdout, stderr, and exit code and completed in under two seconds
  - full `just cli-test`: 523 passed
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just cli-format-check`, and `just cli-analyze`: passed
  - `git diff --check` and runtime submodule `git diff --check`: passed
  - at 2026-07-14 20:16 JST, public
    `inspect-install-profile steam --json` returned
    `installerCompletion.ignoreChildExecutable=steam.exe`, the dependency order
    `corefonts`, `fakejapanese`, `vcrun2022`, and the existing steamwebhelper
    rules; manifest digest
    `5bdcfddd2d21f74b29cb7fc4af7f91c6dce21a8f6ee84788055588d670f0fca3`
    matched the shipped file
  - current process inspection found no remaining profile-install CLI, Wine,
    Steam, or steamwebhelper process; existing Steam metadata contains a
    persisted managed-program binding from a later integrated successful run,
    but that run also includes subsequent native-component work and is not
    claimed as an isolated proof of this commit
  - independent audit repeated all 169 focused tests, public profile inspection,
    schema/domain/environment/lifecycle inspection, source patch comparison,
    and diff checks with no blocking finding
- Remaining risk:
  - direct-process-exit completion deliberately stops waiting for descendant-held
    output after a bounded drain; late descendant diagnostics can be truncated
  - `installerCompletion` is macOS-only and supports one validated executable
    basename; broader completion semantics require a separate design
  - a real reinstall against the active Steam bottle would mutate user data, so
    this PR must rely on preserved dynamic evidence plus non-destructive public
    CLI and deterministic process-fixture verification unless the user requests
    another live installation
  - the installer runner has no new whole-operation timeout; an installer or
    Wine wrapper that never exits for a reason outside the declared child-ignore
    contract remains a separate hang class
