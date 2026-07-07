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

- Timestamp: 2026-07-07 15:11 JST
- State: `in_progress`
- Branch: `main` at `cc7cc76a77623cc0ed9444af2e486bc6e2e3f4ec`.
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
- Remaining work:
  - Wait for the post-merge `Konyak Verify` and `macOS Runtime CLI Smoke` main
    runs to complete successfully.
  - Prepare the `v1.0.8` release notes.
  - Run release preparation through the Nix dev shell, create and push the
    release commit and tag, and dispatch/publish the release.
  - Audit the published GitHub Release, assets, notes, and publish workflow.
- Next action: create the release notes draft, then run `prepare_release.py`
  with `just release-candidate-gates` after post-merge CI is green.
- Verification performed:
  - `git status --short --branch` showed local `main` clean and aligned with
    `origin/main`.
  - `gh release list --repo serika12345/Konyak --limit 10` showed `v1.0.7` as
    the latest published release.
  - `gh run list --repo serika12345/Konyak --branch main --limit 20` showed
    post-merge Pages and Linux runtime smoke passing; Konyak Verify and macOS
    runtime smoke were still in progress at the start of release work.
