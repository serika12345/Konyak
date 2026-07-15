# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-15 11:30 JST
- State: `paused` after the verified CI recovery commit
- Branch: `main`; the CI recovery is committed as
  `fix(ci): restore cross-platform verification` and awaits push.
- Related CI:
  - Konyak Verify: <https://github.com/serika12345/Konyak/actions/runs/29338442739>
  - macOS Profile Installation CLI Smoke:
    <https://github.com/serika12345/Konyak/actions/runs/29338442513>
- Purpose: restore the two failing main-branch CI paths without weakening the
  Golden threshold or broadening the runtime smoke workflow.
- Completed work:
  - reproduced the invalid-bottle Golden test locally and identified that its
    Material icons were not loaded from the bundled test asset, leaving icon
    rasterization dependent on the runner platform
  - loaded `MaterialIcons-Regular.otf` explicitly for that Golden scenario and
    regenerated only the two affected Golden images with real warning and
    delete glyphs
  - reproduced the macOS workflow failure from its log: BSD `realpath` rejects
    the GNU-only `-m` option before the public CLI smoke path starts
  - replaced GNU `realpath -m` and `-ms` usage with the Nix-provided Python
    runtime's portable `os.path.realpath(strict=False)` physical resolution and
    `os.path.abspath` lexical resolution while retaining the destructive root
    and symlink-escape checks
  - added dynamic coverage for ordinary missing paths, symlink plus `..`,
    missing leaves after symlinks, and dangling symlink ancestors; the fixture
    builder and smoke script share byte-identical resolver helpers
  - updated fixture and governance tests before the shell implementation; the
    new expectations failed against the old scripts and pass after the change
- Remaining work:
  - push the fix, then confirm both GitHub Actions runs
- Next action: push the commit, then confirm Konyak Verify on Ubuntu and the
  profile-install smoke on macOS.
- Verification performed:
  - `nix develop -c zsh -lc 'python3 scripts/profile_install_fixture_test.py'`:
    passed, 13 tests
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --plain-name "invalid bottle recovery dialogs match
    goldens"'`: passed, including Golden comparison
  - `nix develop -c zsh -lc 'just verify'`: passed on the final implementation;
    Flutter 507 tests, CLI 550 tests, custom-lint 3 tests, release automation 4
    tests, macOS runtime preparation 6 tests, and fixture 13 tests passed
  - `nix develop -c zsh -lc 'just macos-profile-install-cli-smoke'`: passed on
    the final resolver implementation; `smoke-result.json` ended at
    `2026-07-15T02:23:17Z` with original/final exit 0 and no cleanup failure
  - post-smoke `ps` and `lsof` checks found no fixture or Wine process and no
    TCP 18443 listener; evidence is retained under
    `.dart_tool/konyak/macos-profile-install-cli-smoke/logs`
  - independent audit found no remaining code or safety blocker; it confirmed
    the path resolver matrix, unchanged Golden tolerance, and glyph-only Golden
    updates
- Remaining risk:
  - GitHub Actions confirmation on Ubuntu and macOS remains pending until the
    reviewed fix is committed and pushed
