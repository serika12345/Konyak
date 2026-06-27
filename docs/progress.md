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

- Timestamp: 2026-06-27 13:53 JST
- State: `completed`
- Branch: `codex/d3d12-msvc-fixture`
- Active work: connecting the MSVC/CMake-built D3D12 Windows smoke fixture to
  CI runtime execution.
- Related TODO: end-to-end DLSS/MetalFX rendering proof; this is prerequisite
  probe infrastructure for proving D3D12 runtime behavior through Konyak-owned
  execution paths.
- Purpose: build the small Windows D3D12 executable on GitHub's Windows runner
  and feed the resulting artifact into Konyak runtime smoke execution through
  the public CLI path.
- Completed work: built the fixture successfully in GitHub Actions on branch
  `codex/d3d12-msvc-fixture`; reviewed runtime smoke script and workflow entry
  points; added a failing repository test for the CI artifact handoff; updated
  the macOS runtime smoke workflow to build the Windows D3D12 fixture, upload
  it as `konyak-d3d12-minimal-sample-windows-x64`, download it on the macOS
  smoke job, and pass it to `scripts/run_macos_runtime_cli_smoke.zsh`; updated
  the smoke script to create a `d3d12-msvc-sample` bottle, select the vkd3d
  backend settings, run the executable through `run-program --json`, and wait
  for a `C:\konyak-d3d12-minimal-sample-ok.txt` sentinel file containing
  `KONYAK_D3D12_MINIMAL_SAMPLE_OK`. The first macOS smoke dispatch on commit
  `10dea8d` reached `run-program d3d12-msvc-sample` but failed because the
  macOS Wine runner launches through `wineloader start /unix`, which returns
  before the child process stdout is captured in `latest.log`; the sample now
  mirrors the existing backend probe sentinel contract instead of relying on
  Wine `start` stdout. Sub-agent workstream isolation is not available for this
  task because the multi-agent tool can only spawn agents after an explicit
  user request; investigation, implementation, and audit notes are kept in this
  progress entry and verification logs instead.
- Remaining work: none for connecting the D3D12 fixture to CI runtime smoke.
- Next action: open the branch as a PR when repository permissions allow it.
- Verification: local checks passed:
  `flutter test test/windows_d3d12_fixture_test.dart --plain-name "Windows D3D12
  MSVC fixture has pinned build entrypoints"`; `zsh -n
  scripts/run_macos_runtime_cli_smoke.zsh`; Ruby YAML parsing for
  `.github/workflows/macos-runtime-cli-smoke.yml` and
  `.github/workflows/windows-d3d12-fixture-build.yml`; `git diff --check`;
  `just verify-governance`; `just verify-safety`; `just format-check`;
  `just lint`; `just flutter-test`. GitHub Actions on commit `10dea8d`:
  `Konyak Verify` run `28278439596` passed; `Windows D3D12 Fixture Build` run
  `28278439582` passed; `macOS Runtime CLI Smoke` run `28278442192` built and
  downloaded the D3D12 artifact, passed the existing backend probes, reached the
  D3D12 sample through `run-program`, then failed only because `latest.log`
  lacked stdout marker capture from Wine `start /unix`. GitHub Actions on
  commit `5552dd6`: `Konyak Verify` run `28278817790` passed; `Windows D3D12
  Fixture Build` run `28278817802` passed after the sentinel addition; `macOS
  Runtime CLI Smoke` run `28278820001` passed, with the workflow's Windows job
  building/uploading `konyak_d3d12_minimal.exe`, the macOS job downloading that
  artifact, running `konyak run-program d3d12-msvc-sample ... --json` with
  `{"arguments":"--frames 2","environment":{}}`, observing the sentinel, and
  printing `macOS runtime CLI smoke passed.`
