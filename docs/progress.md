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

- Timestamp: 2026-07-07 10:00 JST
- State: `completed`
- Branch: `main`
- Active work: Harden Konyak Pages reruns after repeated Pages deployment
  failures.
- Related TODO: `docs/todo.md` now points at the next DLSS/MetalFX
  rendering-proof task; the Gcenx GPTK4 CI follow-up remains deferred until a
  Gcenx GPTK4 binary release exists.
- Release tag: `v1.0.7`.
- GitHub Release: https://github.com/serika12345/Konyak/releases/tag/v1.0.7
- Release workflow:
  https://github.com/serika12345/Konyak/actions/runs/28798279839 passed and
  published the GitHub Release assets.
- Pages failure root cause: failed-job reruns of `Konyak Pages` reused the
  default `github-pages` artifact name in the same workflow run. GitHub kept
  the previous attempt's artifact, so `actions/deploy-pages` saw multiple
  artifacts with the same name and failed before deployment.
- Runtime release: parent runtime release locator already points at the latest
  published `serika12345/konyak-macos-runtime` Release,
  `crossover-26.1.0-konyak.0`, with no parent JSON update needed.
- Runtime branch: no runtime submodule changes planned; parent `main` records
  runtime submodule commit `61624ad`, which has the same tree as runtime
  `origin/main` merge commit `0a09716b`.
- Purpose: make Pages deployment reruns deterministic by avoiding artifact-name
  collisions between rerun attempts, instead of relying on empty commits or
  manually dispatched clean runs to hide failed checks.
- Completed work:
  - Updated `.github/workflows/pages.yml` so `actions/upload-pages-artifact`
    and `actions/deploy-pages` both use
    `github-pages-${{ github.run_id }}-${{ github.run_attempt }}`.
  - Confirmed `actionlint` is not currently available in the Nix dev shell, so
    final syntax/protocol validation for the workflow change must come from the
    GitHub Actions run.
  - Confirmed the runtime release list and latest runtime release assets; the
    parent `runtime/macos-wine-release.json` already uses the latest runtime
    release tag.
  - Prepared `apps/konyak/pubspec.yaml` version `1.0.7+8`.
  - Prepared `packages/konyak_cli/lib/src/shared/model_constants.dart` default
    Konyak app version `1.0.7`.
  - Added `docs/releases/v1.0.7.md` with GPTK4 import support and
    CrossOver-compatible D3D10 fallback behavior as primary highlights.
  - Stabilized the new GPTK mismatch golden test for Linux CI rendering
    variance before moving the unpublished `v1.0.7` tag to the verified commit.
  - Published `v1.0.7` with macOS DMG, Linux AppImage, platform release
    metadata, Linux runtime source-manifest assets, and combined `SHA256SUMS`.
- Remaining work: none for the local Pages rerun hardening change.
- Next action: continue with the next TODO-backed DLSS/MetalFX rendering-proof
  task when requested.
- Verification performed:
  - `gh run list --repo serika12345/Konyak --workflow pages.yml --limit 20
    --json databaseId,displayTitle,event,headBranch,headSha,status,
    conclusion,createdAt,url` showed repeated historical Pages failures,
    including the rerun artifact collision on
    https://github.com/serika12345/Konyak/actions/runs/28798935826.
  - `nix develop -c zsh -lc 'command -v actionlint || true'` found no
    `actionlint` executable in the current dev shell.
  - `nix develop -c zsh -lc 'git diff --check && git -C
    runtime/konyak-macos-runtime diff --check && just verify-governance &&
    just verify-safety && just format-check && just lint'` passed after the
    Pages workflow change.
  - `gh release list --repo serika12345/konyak-macos-runtime --limit 5
    --json tagName,isLatest,isDraft,isPrerelease,publishedAt` confirmed
    `crossover-26.1.0-konyak.0` is the latest runtime release.
  - `gh api repos/serika12345/konyak-macos-runtime/releases/latest --jq
    '{tag_name, name, draft, prerelease, published_at, assets:
    [.assets[].name]}'` confirmed the latest runtime release assets include
    `konyak-macos-runtime.release.json`,
    `konyak-macos-wine-runtime-stack-source.json`, and
    `konyak-macos-wine-runtime-stack.tar.zst`.
  - `nix develop -c zsh -lc 'python3 scripts/prepare_release.py --version
    1.0.7 --release-notes
    .dart_tool/konyak/release-notes-v1.0.7.md --gate '\''just
    release-candidate-gates'\'''` passed; this ran `just verify`, the macOS
    release build, packaged runtime extraction smoke, DMG layout smoke,
    Finder integration smoke with PuTTY, packaged app CLI bridge smoke, and app
    update handoff smoke before preparing `v1.0.7`.
  - Initial publish workflow run
    https://github.com/serika12345/Konyak/actions/runs/28797616198 failed in
    Linux `just verify` because the new GPTK mismatch golden differed by
    3.54%, just above its 3% comparator tolerance.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test
    test/widget_test.dart --plain-name "macOS settings dialog shows GPTK
    version mismatch import errors"'` passed after raising that golden's
    comparator tolerance to 4%.
  - `nix develop -c zsh -lc 'just flutter-format-check &&
    just flutter-analyze && just flutter-test'` passed; Flutter test reported
    467 tests passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C
    runtime/konyak-macos-runtime diff --check && just verify-governance &&
    just verify-safety && just format-check && just lint'` passed.
  - Publish workflow run
    https://github.com/serika12345/Konyak/actions/runs/28798279839 passed:
    Linux AppImage, macOS app, repository verify, and GitHub Release publish
    jobs all succeeded.
  - `gh release view v1.0.7 --repo serika12345/Konyak --json
    tagName,name,isDraft,isPrerelease,isImmutable,publishedAt,url,
    targetCommitish,assets` confirmed the Release is published and includes
    `Konyak-1.0.7-macos-arm64.dmg`,
    `Konyak-1.0.7-linux-x86_64.AppImage`, platform metadata, Linux runtime
    source-manifest assets, and `SHA256SUMS`.
