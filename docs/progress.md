# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 21:27 JST
- State: `paused`
- Branch: `feat/declarative-native-components`; based on the `main` merge of
  PR #58 (`e7e8441`) and carrying source commit `2be21c1`; the code-only
  cherry-pick was `0639767` before this handoff documentation was amended.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system", bounded native-component milestone.
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: replace the profile's verb-only dependency list with ordered,
  declarative pre-install actions and add CrossOver-style x86/x64
  `d3dcompiler_47` placement without creating a Wine DLL override.
- Completed work:
  - merged PR #58, fast-forwarded `main`, and created this focused branch
  - cherry-picked the source native-component commit without a code conflict;
    its stable patch ID matches source commit `2be21c1`
  - replaced the unreleased verb-only dependency shape with an ordered union of
    bounded winetricks and native-DLL pre-install actions across schema, domain,
    persisted metadata, versioned CLI JSON, Flutter parsing, and Profile Manager
  - added x86/x64 `d3dcompiler_47` resources to the Steam profile after
    `corefonts` and `vcrun2022`, before `fakejapanese` and the Steam installer
  - added resource-first download and SHA verification so no Wine-side action
    starts unless the installer and both native resources are available
  - added native placement validation for PE machine, digest, real-path and
    symlink boundaries, idempotent reruns, and atomic replacement while keeping
    the existing target on failure and writing no DLL override
  - completed separate implementation, source/artifact investigation, and
    independent result-audit workstreams with no functional code blocker
- Remaining work:
  - review the focused pull request and decide the pre-release compliance
    posture for DLLs downloaded from the fixed `mozilla/fxc2` commit: replace
    them with a Microsoft-owned, explicitly licensed acquisition route or
    explicitly accept the current external source before release
  - after this pull request merges, advance IP-S6 as a separate pull request to
    add the maintained public-CLI profile-install smoke and isolated CI job
- Next action: review this focused pull request, with particular attention to
  the external DLL source; after merge, resolve that release blocker and advance
  IP-S6 before claiming the complete profile-installation gate.
- Verification performed:
  - source commit `2be21c1` and cherry-picked commit `0639767` have the same
    stable patch ID, `fa54bca2d13809b74966d809e552d612c32472a9`
  - focused CLI/domain/I/O verification passed with 183 tests in the
    implementation workstream and 91 independently selected tests in the
    investigation workstream; the full `just cli-test` passed with 550 tests
  - focused Flutter contract verification passed with 96 tests, the three
    focused widget tests passed, and the full `just flutter-test` passed with
    507 tests
  - the Profile Manager golden test passed and
    `apps/konyak/test/goldens/profile_manager_automatic_install.png` was
    visually inspected; all five ordered actions are readable without clipping
  - at 2026-07-14 21:11-21:12 JST, read-only inspection of the active Steam
    bottle confirmed regular x86 and x64 files in SysWOW64 and System32 with
    the manifest SHA-256 values and PE machines `0x014c` and `0x8664`; no
    `d3dcompiler` entry exists in any bottle registry file
  - at 2026-07-14 21:14 JST, HEAD-only availability checks returned HTTP 200
    and the expected content lengths for both fixed GitHub raw URLs
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just cli-format-check`, `just cli-analyze`,
    `just flutter-format-check`, `just flutter-analyze`, `git diff --check`,
    and the runtime submodule diff check passed through the Nix dev shell
  - no workflow changes are included because this pull request adds the
    deterministic contract and implementation but does not claim a maintained
    local runtime smoke; IP-S6 remains the explicit follow-up that will add the
    public CLI smoke and matching independently rerunnable Actions job
- Remaining risk:
  - `mozilla/fxc2` records that the DLLs came from Firefox 102.5 ESR but has no
    repository license; fixed SHA values establish integrity, not redistribution
    authority, authenticity, long-term availability, or a GitHub service level
  - installation is not profile-wide transactional: a later failure stops
    subsequent actions and persistence but does not roll back earlier successful
    winetricks, DLL, or installer side effects; each DLL replacement itself is
    atomic and preserves the old target on failure
  - resource cleanup ownership is removed before deletion succeeds, so a rare
    root/path change or transient filesystem failure can leave an unretryable
    staging directory in the process; this behavior predates the native-resource
    change but remains a follow-up hardening candidate
  - real-path and symlink checks do not eliminate same-UID time-of-check races,
    and rename gives atomic visibility but not crash durability without a
    directory fsync
  - the current read-only artifact audit confirms the user's successful GUI
    result but does not replace IP-S6's future public-CLI sequence, process,
    log, and CI evidence
