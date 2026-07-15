# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-15 16:42 JST
- State: `in_progress` pending hosted Actions confirmation
- Branch: `main`; the verified CI correction is included in this change
- Related CI:
  - failing Konyak Verify:
    <https://github.com/serika12345/Konyak/actions/runs/29395307987>
  - passing macOS Profile Installation CLI Smoke:
    <https://github.com/serika12345/Konyak/actions/runs/29387929376>
- Purpose: restore the complete Ubuntu verification path while keeping the
  macOS-only development-shell contract covered on a macOS runner.
- Completed work:
  - confirmed the portable path-resolution fix on the hosted macOS runner
  - reproduced the invalid-bottle Golden failures in an isolated x86_64 Linux
    VM using the repository Nix flake; the local failure percentages exactly
    match Actions at 2.30% and 2.54%
  - captured the Linux test, master, isolated-diff, and masked-diff images under
    `/tmp/konyak-linux-failures`
  - proved the process-global font-state leak dynamically: the Japanese pin
    Golden passes alone on x86_64 Linux but fails at 13.27% after the
    invalid-bottle test loads `MaterialIcons`; the ordered three-test run also
    reproduced the Wine prompt's 2.02% failure exactly
  - moved `MaterialIcons` into the common Golden font initialization so every
    selected or ordered Golden test starts from the same explicit font set
  - added Linux-specific baselines for only the two invalid-bottle images while
    preserving the existing non-Linux paths and all comparison tolerances
  - regenerated the Japanese pin and Wine update prompt images with the real
    Material icon glyphs instead of missing-glyph boxes
  - passed the affected ordered three-test sequence on both macOS and an
    isolated x86_64 Linux VM
  - passed the same `nix develop -c zsh -lc 'just verify'` command used by the
    failing Actions job
  - completed an independent audit with no blocker; the auditor reran the
    ordered tests against byte-identical host/container inputs, decoded all
    four changed images, and confirmed unchanged tolerances and production code
  - confirmed the Golden correction on hosted Ubuntu: all 507 Flutter tests,
    including the three previously failing Golden tests, passed in run
    `29395307987`
  - identified the new failure after Flutter and CLI completed: the
    macOS-specific development-shell manifest override test runs unconditionally
    on Ubuntu even though the corresponding shell hook is intentionally Darwin
    only
  - scoped that manifest override assertion to Darwin and added a separate,
    lightweight macOS Actions job so the platform contract remains covered
    without coupling it to the expensive profile-install smoke jobs
  - reproduced the remaining fixture-test failure with the exact
    `nix develop -c zsh -lc` invocation and confirmed that its login shell
    selects host Python 3.9.6, where `realpath(..., strict=False)` is unsupported
  - retained the same missing-path-tolerant behavior with the Python 3.9-compatible
    default `realpath(path)` call in both byte-identical path helpers
  - updated the workflow contract test to verify all three checkout steps
    independently require `persist-credentials: false`
  - passed the complete local `just verify` gate after all corrections
- Remaining work:
  - confirm the hosted Ubuntu verification and the new macOS preparation job
- Next action: push the correction and monitor both hosted checks to completion.
- Verification performed:
  - hosted macOS Profile Installation CLI Smoke run `29387929376`: passed
  - isolated x86_64 Linux/Nix invalid-bottle Golden test: failed as expected at
    2.30% (17,195 pixels) and 2.54% (19,047 pixels), reproducing Actions run
    `29387929386`
  - isolated x86_64 Linux/Nix ordered three-test reproduction before the fix:
    failed at the same 2.30%, 2.54%, 13.27%, and 2.02% as Actions
  - macOS and x86_64 Linux ordered three-test verification after the fix: passed
  - `nix develop -c zsh -lc 'just verify'`: passed; Flutter 507 tests, CLI 550
    tests, custom-lint 3 tests, release automation 4 tests, macOS runtime
    preparation 6 tests, and profile-install fixture 13 tests passed
  - independent audit: macOS ordered three tests passed, synchronized x86_64
    Linux ordered three tests passed, `just verify-governance` and
    `git diff --check` passed, and all four changed PNGs decoded successfully
  - hosted Ubuntu run `29395307987`: Flutter 507 tests, CLI 550 tests, and
    custom-lint 3 tests passed; `prepare_macos_dev_runtime_stack_test.py` then
    failed two subcases because the Darwin-only exported variable is absent on
    Linux
  - `nix develop -c zsh -lc 'just verify'`: passed after the complete
    correction; Flutter 507 tests, CLI 550 tests, custom-lint 3 tests, release
    automation 4 tests, macOS runtime preparation 6 tests, and profile-install
    fixture 13 tests passed
  - targeted macOS audit: all 6 runtime preparation tests passed on macOS; a
    Linux-platform injection passed 5 tests and skipped only the Darwin contract
  - workflow YAML parsing, governance verification, and `git diff --check`:
    passed
  - independent Python 3.9 compatibility audit: fixture tests 13/13 passed,
    missing-tail `realpath(path)` behavior was proven dynamically, and both
    127-byte path helpers were byte-identical
- Remaining risk:
  - hosted Actions confirmation is still pending
  - the checkout security contract test intentionally follows the workflow's
    current indentation and string structure rather than parsing a YAML AST
