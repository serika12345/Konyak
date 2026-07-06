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

- Timestamp: 2026-07-06 18:37 JST
- State: `paused`
- Branch: `task/gptk4-runtime-import-smoke`
- Active work: `G3-P2 GPTK4 Runtime Submodule Import and Smoke Contract`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G3-P2 GPTK4 Runtime Submodule Import and Smoke Contract`.
- Pull request: parent PR https://github.com/serika12345/Konyak/pull/38 is
  open as draft. Runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/4 is open as draft.
  Previous parent PR https://github.com/serika12345/Konyak/pull/37 merged as
  `2445a0d`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`; parent PR https://github.com/serika12345/Konyak/pull/36
  merged as `4e56d49`; parent PR https://github.com/serika12345/Konyak/pull/37
  merged as `2445a0d`.
- Runtime branch: `runtime/konyak-macos-runtime` branch
  `task/gptk4-runtime-import-smoke`, based on runtime `main` commit
  `eedc190`, latest commit `f8e3652`.
- Purpose: make the runtime-owned GPTK/D3DMetal import scripts, smoke checks,
  and CI preparation accept GPTK4 payloads without `atidxx64.*`, while keeping
  GPTK3 smoke green and preserving the no-active-`d3d10.*` contract.
- Workstream separation: sub-agent spawning is not available for this turn
  because the tool is restricted to explicit user requests. Investigation,
  implementation, and audit evidence will be kept separate in this snapshot and
  in `docs/gptk-d3dmetal-import-progress.md`.
- Completed work: PR #37 was merged; local parent `main` was fast-forwarded to
  `2445a0d`; created parent branch `task/gptk4-runtime-import-smoke`; updated
  runtime submodule checkout from `9f8f43a` to runtime `main` merge commit
  `eedc190`; created runtime branch `task/gptk4-runtime-import-smoke`; updated
  runtime import, CI preparation, backend smoke, archive exclusion, workflow,
  and runtime contract docs so GPTK4 payloads without `atidxx64.*` are accepted
  while GPTK3 still requires `atidxx64.*`; proved GPTK3 and GPTK4 maintained
  local smoke against `dist/konyak-macos-wine-runtime-stack.tar.zst`; opened
  runtime PR #4 and parent PR #38 as drafts.
- Remaining work: review CI and merge runtime PR #4 first, then update or merge
  parent PR #38 for the submodule pointer/docs.
- Next action: review the G3-P2 PRs and, after approval, merge runtime PR #4
  before the parent PR.
- Verification so far:
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/import-gptk-d3dmetal-redist.zsh scripts/prepare-gptk-d3dmetal-ci-smoke.zsh scripts/smoke-backend-device.zsh scripts/smoke-gptk-d3dmetal-local.zsh scripts/check-runtime-archive-excludes-gptk.zsh'`
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk4-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK4 was detected, `gptk-d3d10-unsupported`,
    `gptk-d3d11-device`, and `gptk-d3d12-device` passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk3-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK3 was detected and the same GPTK smoke targets passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#gnutar -c ./scripts/check-runtime-archive-excludes-gptk.zsh dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
