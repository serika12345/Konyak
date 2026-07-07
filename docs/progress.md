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

- Timestamp: 2026-07-07 15:30 JST
- State: `completed`
- Branch: `main` at `136f32e94226d07df27aacbf83c45dbf3c218741`;
  tag `v1.0.8`.
- Active work: publish Konyak `v1.0.8`.
- Related TODO: no long-running TODO item; this is the application release for
  the merged runtime update UI and macOS runtime release-check work.
- Purpose: make the runtime update UI, macOS Wine runtime release feed
  integration, and `crossover-26.1.0-konyak.1` runtime availability visible to
  users through a normal Konyak release.
- Completed work:
  - Fast-forwarded local `main` to `origin/main` after PR #41 was merged.
  - Confirmed `v1.0.7` is the latest published Konyak Release and `v1.0.8`
    does not already exist locally.
  - Confirmed the release delta from `v1.0.7` includes the Wine runtime update
    UI, app-menu runtime update check wiring, macOS runtime release URL
    override, runtime update CLI contract tests, and the submodule pointer to
    `runtime/konyak-macos-runtime` commit
    `6f84a6d58662287aa01781caf2ac02399e8a044`.
  - Confirmed all post-merge main CI runs for PR #41 passed before release:
    `Konyak Verify`, `Konyak Pages`, Linux runtime CLI smoke, and macOS runtime
    CLI smoke.
  - Prepared `docs/releases/v1.0.8.md` with runtime update UI and
    GPTK4-capable runtime release notes.
  - Ran release preparation through the Nix dev shell, bumped the app from
    `1.0.7+8` to `1.0.8+9`, created release commit
    `136f32e94226d07df27aacbf83c45dbf3c218741`, created tag `v1.0.8`, pushed
    both to origin, and dispatched the publish workflow.
  - Published GitHub Release
    `https://github.com/serika12345/Konyak/releases/tag/v1.0.8`.
  - Audited the published release assets, release body, macOS/Linux release
    metadata, and SHA-256 checksum files.
- Remaining work: none for the `v1.0.8` application release.
- Next action: continue the next roadmap item from `docs/todo.md`.
- Verification performed:
  - `git status --short --branch` showed local `main` clean and aligned with
    `origin/main`.
  - `gh release list --repo serika12345/Konyak --limit 10` showed `v1.0.7` as
    the latest published release.
  - `gh run list --repo serika12345/Konyak --branch main --limit 20` showed
    post-merge Pages and Linux runtime smoke passing; Konyak Verify and macOS
    runtime smoke were still in progress at the start of release work.
  - `gh run watch 28845362690 --repo serika12345/Konyak --exit-status
    --interval 30` passed for the post-merge macOS runtime CLI smoke.
  - `nix develop -c zsh -lc 'python3 scripts/prepare_release.py --version
    1.0.8 --release-notes .dart_tool/konyak/release-notes-v1.0.8.md --gate
    "just release-candidate-gates" --commit --tag --push --push-branch main
    --dispatch-publish'` passed.
  - `gh run watch 28846025368 --repo serika12345/Konyak --exit-status
    --interval 30` passed for the `v1.0.8` publish workflow.
  - `gh release view v1.0.8 --repo serika12345/Konyak --json
    tagName,name,isDraft,isPrerelease,isImmutable,publishedAt,url,
    targetCommitish,assets,body` showed a non-draft, non-prerelease latest
    release with the expected macOS DMG, Linux AppImage, metadata, checksum,
    and Linux runtime source-manifest assets.
  - Downloaded the published `*.release.json`, `*.sha256`, and `SHA256SUMS`
    assets from `v1.0.8`; both platform metadata files report version `1.0.8`
    and their SHA-256 values match the published checksum files.
