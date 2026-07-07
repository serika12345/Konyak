# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-07-07 15:00 JST
- State: `completed`
- Branch: parent `codex/runtime-wine-update-ui`; runtime
  `runtime/konyak-macos-runtime` `main` at
  `6f84a6d58662287aa01781caf2ac02399e8a044`.
- Active work: publish a new `serika12345/konyak-macos-runtime` GitHub Release
  for the GPTK4-capable runtime.
- Related TODO: no long-running TODO item; this is the runtime release artifact
  required for the completed GPTK4/runtime update work to be observable from the
  production release feed.
- Purpose: the latest runtime CI run succeeded but reused the existing
  `crossover-26.1.0-konyak.0` tag, so GitHub updated the old Release instead
  of adding a new one. Produce an actual new runtime Release by bumping the
  Konyak-owned runtime revision while keeping the CrossOver source version at
  `26.1.0`.
- Completed work:
  - Confirmed the public runtime Releases page still shows only
    `crossover-26.1.0-konyak.0`.
  - Confirmed the latest runtime `Build runtime` main run succeeded and the
    publish job completed.
  - Identified the release-version root cause: runtime version generation still
    hardcodes `konyak.0` in Nix derivations and source-manifest generation.
  - Added explicit Konyak runtime release revision metadata and generated
    `crossover-26.1.0-konyak.1` release metadata while keeping the CrossOver
    source version at `26.1.0`.
  - Added runtime release-version and Wine payload-stamping scripts so a
    Konyak release revision bump does not force a Wine binary rebuild when the
    Wine build identity is unchanged.
  - Updated normal and candidate release workflows to create new release tags
    with `--target "$GITHUB_SHA"`.
  - Published GitHub Release
    `https://github.com/serika12345/konyak-macos-runtime/releases/tag/crossover-26.1.0-konyak.1`.
  - Merged runtime PR
    `https://github.com/serika12345/konyak-macos-runtime/pull/6` into runtime
    `main` with `[skip ci]` after the release workflow passed, and cancelled
    the redundant pull-request workflow run.
- Remaining work: none for this runtime release.
- Next action: continue parent PR review/merge for the runtime update UI and
  release-check wiring.
- Verification performed:
  - `gh release list --repo serika12345/konyak-macos-runtime --limit 10`
    showed only `crossover-26.1.0-konyak.0`.
  - `gh run view 28790344840 --repo serika12345/konyak-macos-runtime` showed
    the latest main `Build runtime` run completed successfully, including
    `Publish runtime release`, on commit
    `0a09716b3e2df5ca64959cbf4cfc93d94beb7c55`.
  - `nix develop -c zsh -lc 'git diff --check; nix shell nixpkgs#actionlint -c
    actionlint .github/workflows/build-runtime.yml
    .github/workflows/promote-runtime-candidate.yml; nix flake check
    --all-systems --no-build -L --show-trace'` passed in
    `runtime/konyak-macos-runtime`.
  - Runtime `Build runtime` workflow run `28842870557` completed successfully,
    including `Publish runtime release`.
  - `gh release list --repo serika12345/konyak-macos-runtime --limit 5` shows
    `Konyak macOS runtime crossover-26.1.0-konyak.1` as `Latest`.
  - `gh release view crossover-26.1.0-konyak.1 --repo
    serika12345/konyak-macos-runtime` reports a non-draft, non-prerelease
    release targeting commit `67112ba4c221e547774a22fff56c5831840fa205` with
    the expected three assets.
  - Downloaded `konyak-macos-runtime.release.json` and
    `konyak-macos-wine-runtime-stack-source.json` from the release; metadata
    version and Wine component version are both
    `crossover-26.1.0-konyak.1`.
  - Downloaded the published stack archive and inspected
    `.konyak-runtime-stack.json`; the Wine component version is
    `crossover-26.1.0-konyak.1`.
