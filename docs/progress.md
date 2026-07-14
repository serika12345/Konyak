# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 20:56 JST
- State: `paused`
- Branch: `fix/windows-path-pin-icons`; based on the `main` merge of PR #57
  (`9d10253`) and carrying the Windows-path icon correction originally committed
  as `d346ecf`, plus the path-validation hardening found during this delivery
  audit.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: restore icons for pinned executables whose portable persisted
  identity is an absolute Wine Windows path, without replacing that identity
  with a bottle-location-dependent host path.
- Completed work:
  - merged PRs #50 through #57 through the installer-launched application
    completion fix, fast-forwarded `main`, and created this focused branch
  - extracted Wine Windows-to-host path conversion into a shared I/O boundary
    used by shortcut, pinned-program, and Wine process metadata
  - resolved valid `C:\\...` pins to their bottle `drive_c` file only for PE
    metadata and icon access while preserving the Windows path in persistence
  - covered ICO extraction for both newly pinned and existing Windows-path
    programs through the public CLI contract
  - hardened the mapper to accept only supported absolute C/Z paths or clean
    absolute POSIX paths and to reject drive-relative, unsupported-drive,
    dot-segment, NUL, and control-character inputs
  - prevented rejected drive-like or absolute external paths from falling back
    to relative host file access in synchronous and asynchronous metadata
    extraction
  - added isolated public-list coverage proving malformed persisted pins remain
    readable with their path unchanged and no icon, plus a zone-scoped I/O probe
    proving no host `File` is opened for them
  - completed separate investigation, implementation, and independent result
    audits; all path-validation and test-isolation blockers were corrected
- Remaining work:
  - review and merge this focused pull request before advancing to the next
    cherry-picked profile-installation step
- Next action: after this pull request merges, start the focused native-component
  profile change from source commit `2be21c1`.
- Verification performed:
  - source investigation reproduced the missing icon through the public CLI:
    the real Steam PE and shortcut parser were valid, but a non-shortcut
    `C:\\...` path was passed directly to the macOS filesystem
  - at 2026-07-14 15:11 JST, isolated public `list-bottles --json` against the
    real read-only Steam `drive_c` kept the Windows pin identity and generated a
    70,124-byte ICO containing 13 images while leaving real user metadata inode,
    size, and modification time unchanged
  - at 2026-07-14 20:34 JST, read-only inspection confirmed the active Steam PE
    and its cached 70,124-byte, 13-image ICO while leaving the active bottle
    untouched; active listing was deliberately not rerun because hydration may
    write icon cache or launcher files
  - TDD captured failures for missing new/existing pin icons, drive-relative and
    unsafe path acceptance, invalid POSIX passthrough, accidental relative host
    fallback, and a global-current-directory test leak before each correction
  - mapper, pinned-program, and runtime/process focused suites passed with 4,
    28, and 64 tests respectively; the independent audit reran the relevant 96
    tests and reported no remaining blocker
  - `just cli-test` passed with 531 tests after removing the test's global
    current-directory mutation
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just cli-format-check`, `just cli-analyze`,
    `git diff --check`, and the runtime submodule diff check passed
  - no workflow update is needed: the deterministic public CLI regressions run
    in the existing CLI test job and no new runtime, packaging, or launcher
    execution path was introduced
- Remaining risk:
  - C-drive mapping provides lexical containment but does not realpath-check
    symlinks inside `drive_c`; Z-drive and POSIX pins intentionally retain the
    existing external-host-program policy and this mapper is not a sandbox
  - Windows path components retain their original case, so icon lookup can fail
    on a case-sensitive host when component case differs from the filesystem
  - listing can create or refresh bottle-local icon cache and launcher files,
    but it must not rewrite the portable pin identity or persisted bottle
    metadata
  - Windows-path `.lnk` files themselves are outside this focused fix; the
    existing host-path shortcut flow remains covered and passing
