# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 19:54 JST
- State: `paused`
- Branch: `fix/macos-development-runtime-latest`; based on the `main` merge of
  PR #54 (`d9a16fc`) and carrying the runtime correction originally committed
  as `10cd370`. The latest commit is the branch HEAD named
  `fix(runtime): default macos development to latest`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: make the macOS development runtime follow the runtime-owner-published
  latest source manifest by default, while retaining explicit rollback and
  local-manifest overrides and keeping the runtime submodule artifacts as SSOT.
- Completed work:
  - merged PRs #50 through #54 for installer resources, profile installation,
    dependency-first execution, Profile Manager installation, and invalid
    bottle recovery
  - fast-forwarded local `main` to the PR #54 merge and created the focused
    runtime branch
  - applied the parent-repository runtime policy, CLI fallback, Nix/VSCode/Agent
    Watch launcher, prepare-script, documentation, governance, and test changes
    from `10cd370`
  - kept the runtime owner responsible for complete component archives and
    source manifests; no runtime submodule files or parent-side component
    overlays are changed
  - verified that blank development manifest input resolves to the
    runtime-owner `latest` source manifest, while explicit release-tag and
    complete-manifest overrides retain deterministic rollback paths
  - verified that a fresh Nix development shell replaces inherited stale
    derived development variables with repository SSOT values
  - completed focused tests, full required gates, isolated maintained-script
    source selection, read-only public CLI runtime parity, and an independent
    artifact/result audit
  - confirmed that existing GitHub Actions already run `just verify`, the
    maintained preparation tests, and the public macOS runtime CLI smoke for
    the files changed by this branch; no workflow change is required
- Remaining work:
  - submit this focused runtime pull request and wait for review and merge
  - after merge, update local `main`, create the next focused branch, and apply
    `e6b2824` for the Steam font and Visual C++ profile dependencies
- Next action: push the focused branch, open the pull request, and stop at the
  review gate.
- Verification performed:
  - focused Dart runtime contract tests: 55 passed
  - `just macos-dev-runtime-prepare-test`: 6 passed
  - full `just cli-test`: 502 passed
  - `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, `just cli-format-check`, and `just cli-analyze`: passed
  - `git diff --check` and runtime submodule `git diff --check`: passed
  - maintained prepare-script source selection at
    `.dart_tool/konyak/macos-latest-source-audit-20260714-194650`: selected the
    runtime-owner `releases/latest/download` source, cached matching source
    metadata, and resolved Wine `crossover-26.1.0-konyak.4`
  - explicit padded fixed-tag and complete-manifest overrides were normalized
    and selected; inherited stale derived variables were replaced in a fresh
    Nix development shell
  - read-only public `dart run bin/konyak.dart list-runtimes --json` at
    2026-07-14 19:51 JST reported an installed, complete stack whose 10
    component versions matched the selected latest manifest
  - independent read-only audit repeated SSOT/platform focused tests (7
    passed), runtime install contracts (48 passed), preparation tests (6
    passed), governance, VSCode JSON parsing, override selection, Agent Watch
    input normalization, isolated latest-manifest retrieval, and submodule
    pointer inspection; no implementation or artifact blocker was found
- Remaining risk:
  - `latest` is intentionally mutable, so deterministic rollback depends on the
    explicit release-tag or complete-manifest override
  - HTTPS and component SHA-256 checks protect component retrieval, but manifest
    authenticity and fully reproducible selection still depend on an explicit
    fixed-tag, complete-manifest, or signature override
  - callers that previously set derived `KONYAK_DEV_*` values directly must use
    the documented `_OVERRIDE` variables; maintained Nix, VSCode, and Agent
    Watch paths already use the new contract
