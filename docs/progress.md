# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 20:09 JST
- State: `paused`
- Branch: `feat/steam-font-vc-dependencies`; based on the `main` merge of PR
  #55 (`7eb5958`) and carrying the profile dependency change originally
  committed as `e6b2824`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: bring the built-in Steam profile closer to the current CrossOver 26
  launcher dependency set by adding the Japanese font replacement and Visual
  C++ runtime dependencies that the existing declarative winetricks contract
  can express safely.
- Completed work:
  - merged PRs #50 through #55 for installer resources, profile installation,
    dependency-first execution, Profile Manager installation, invalid bottle
    recovery, and latest macOS development-runtime selection
  - fast-forwarded local `main` to the PR #55 merge and created this focused
    dependency branch
  - applied the Steam profile order `corefonts`, `fakejapanese`, `vcrun2022`
    ahead of the installer, plus matching catalog and Profile Manager tests
  - applied the updated 1040x720 Profile Manager golden fixture showing all
    three dependencies
  - documented a separate bounded native-component milestone for exact
    CrossOver-style `d3dcompiler_47` placement without a DLL override
  - verified through the public read-only CLI path that the shipped manifest
    exposes all three dependencies in declaration order and that the managed
    runtime winetricks catalog provides every declared verb
  - regenerated, reran, and visually inspected the 1040x720 Profile Manager
    golden; all three dependency rows and both actions are visible without
    overlap or clipping
  - completed the focused CLI and Flutter tests, full required gates, a
    read-only dependency investigation, and an independent artifact/result
    audit with no implementation blocker
- Remaining work:
  - review and merge the focused pull request for this branch
  - after merge, update local `main`, create the next focused branch, and apply
    `b0e6860` for installer completion when the launched application remains
    alive
- Next action: review and merge the pull request for this branch; do not advance
  to `b0e6860` before that merge is confirmed.
- Verification performed:
  - focused catalog tests: 30 passed
  - independent focused catalog, installer, and public contract tests: 45
    passed
  - Profile Manager golden regeneration and focused comparison: 1 passed each
  - full `just cli-test`: 502 passed
  - full `just flutter-test`: 503 passed
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just cli-format-check`, `just cli-analyze`,
    `just flutter-format-check`, and `just flutter-analyze`: passed
  - `git diff --check` and runtime submodule `git diff --check`: passed
  - at 2026-07-14 20:01 JST, public `inspect-install-profile steam --json`
    returned `corefonts`, `fakejapanese`, and `vcrun2022` in declaration order
    with manifest digest
    `f75cbdb2e0440444e7d5ea7c9dc6ab9be22c1555a9a4daeadb1116e2d040304b`
  - public `list-winetricks-verbs --json` confirmed all three verbs are present
    in the managed runtime catalog without invoking Wine directly
  - at 2026-07-14 20:06 JST, public `list-bottles --json` identified the active
    Steam bottle; its read-only `winetricks.log` contained `corefonts`,
    `vcrun2022`, `sourcehansans`, and `fakejapanese`, confirming prior real
    installation of the selected dependency set
  - visually inspected
    `apps/konyak/test/goldens/profile_manager_automatic_install.png`; it is a
    1040x720 RGBA image with SHA-256
    `01ae12c76907b941461153713a231b13e8d49648525144faf400c8dc7264e7f7`
  - independent audit confirmed the file digest matches the public profile
    digest, the installer preserves declaration order, the change is standalone
    from `b0e6860`, and no new dependency, arbitrary script, external binary,
    runtime submodule, or licensing change is introduced
- Remaining risk:
  - `fakejapanese` replaces Japanese-font mappings and is broader than merely
    installing an additional font
  - `vcrun2022` is the closest bundled winetricks representation of the current
    VC++ x86/x64 runtime, not a byte-for-byte CrossOver dependency recipe
  - the standard winetricks `d3dcompiler_47` verb is intentionally excluded
    because it creates a native DLL override that does not match CrossOver;
    exact native component placement remains a separate milestone
  - existing bottles are not retrofitted automatically; the dependency list is
    applied by new automatic profile installs
  - future winetricks download changes can fail explicitly until the
    runtime-owner updates and verifies its bundled recipe and digests
