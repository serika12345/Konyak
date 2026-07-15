# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-15 15:46 JST
- State: `in_progress` pending hosted Ubuntu confirmation
- Branch: `main`; the independently audited Golden correction is ready for the
  requested commit and push
- Related CI:
  - failing Konyak Verify:
    <https://github.com/serika12345/Konyak/actions/runs/29387929386>
  - passing macOS Profile Installation CLI Smoke:
    <https://github.com/serika12345/Konyak/actions/runs/29387929376>
- Purpose: finish the Ubuntu Golden recovery without weakening comparison
  tolerances or changing production UI behavior.
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
- Remaining work:
  - confirm the new Konyak Verify run on hosted Ubuntu after this correction is
    pushed
- Next action: confirm the Konyak Verify workflow on hosted Ubuntu.
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
- Remaining risk:
  - hosted Ubuntu Actions confirmation remains pending
