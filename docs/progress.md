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

- Timestamp: 2026-06-27 18:53 JST
- State: `completed`
- Branch: `main`
- Active work: add static graphics backend selection hints for Windows
  programs.
- Related TODO: none; this is a focused UX/CLI contract improvement for
  choosing existing graphics backends.
- Purpose: inspect a selected Windows program without running it and surface
  candidate graphics backend hints through the existing CLI-to-Flutter
  boundary.
- Completed work: read current TODO/progress state, Flutter architecture notes,
  the run program dialog, CLI program command handling, PE metadata parsing,
  runtime settings models, and bottle graphics settings controls; added
  `suggest-graphics-backend --program <path> --json`; extended PE parsing with
  import DLL names; added static graphics signal analysis for D3D9, D3D10/11,
  D3D12, OpenGL, and Vulkan hints; added Flutter CLI parsing and a run dialog
  hint button/result panel; added English/Japanese localization entries; added
  CLI, client, widget, localization, and golden coverage.
- Remaining work: none for the static hint path.
- Next action: review the uncommitted diff and commit when ready.
- Verification: focused tests passed:
  `cd packages/konyak_cli && dart test test/cli_contract_test.dart --name
  "suggest-graphics-backend"`, `cd apps/konyak && flutter test
  test/cli/konyak_cli_client_test.dart --plain-name "loads graphics backend
  hints through the JSON CLI contract"`, `cd apps/konyak && flutter test
  test/widget_test.dart --plain-name "run program dialog displays graphics
  backend hints"`, `cd apps/konyak && flutter test test/widget_test.dart
  --plain-name "run program dialog requests graphics backend hints from the
  CLI"`, and `cd apps/konyak && flutter test
  test/app/localization_resources_test.dart`. Generated and rechecked golden
  artifact:
  `apps/konyak/test/goldens/run_program_dialog_graphics_hint.png`.
  Required gates passed: `just verify-governance`, `just verify-safety`,
  `just format-check`, `just lint`, `just flutter-format-check`, `just
  flutter-analyze`, `just flutter-test`, and `just cli-test`. `git diff
  --check` passed.

- Timestamp: 2026-06-27 14:58 JST
- State: `completed`
- Branch: `codex/visible-graphics-smoke`
- Active work: require macOS runtime CI and local graphics checks to use
  minimal samples that create visible windows and clear/present through the
  selected backend.
- Related TODO: end-to-end DLSS/MetalFX rendering proof; this tightens the
  prerequisite graphics smoke contract so backend validation is based on
  visible rendering samples rather than device-only probes.
- Purpose: replace D3D11/D3D12 backend device-only smoke execution with
  Konyak-owned visible graphics samples run through the public CLI path.
- Completed work: read the current TODO/progress state; inspected the existing
  macOS runtime CLI smoke script, D3D11 visible probe, D3D11/D3D12 device
  probes, and workflow triggers; updated repository contract tests so the
  parent macOS runtime smoke rejects device-only probes and expects visible
  graphics samples; added a sentinel file to the visible D3D11 sample after its
  clear/present loop; changed the parent runtime CLI smoke script to build and
  run visible D3D11 samples for DXVK-macOS and DXMT; changed the D3D12 MSVC
  smoke to run as a visible sample, selecting D3DMetal automatically when the
  local runtime has the user-imported GPTK/D3DMetal component and otherwise
  falling back to the non-GPTK D3D12 backend so parent CI does not download or
  overlay proprietary GPTK payloads; updated workflow path triggers to watch
  visible sample sources instead of runtime-submodule device probes.
- Remaining work: none for the parent repository visible-sample smoke path.
  Runtime-submodule direct Wine backend probe jobs remain separate low-level
  diagnostics and were not changed in this parent-repository task.
- Next action: push `codex/visible-graphics-smoke` and run GitHub Actions
  workflow dispatch for CI confirmation.
- Verification: focused tests passed:
  `flutter test test/macos_window_metrics_test.dart --plain-name "macOS runtime
  CLI smoke runs visible graphics samples through the CLI"` and `flutter test
  test/windows_d3d12_fixture_test.dart --plain-name "Windows D3D12 MSVC fixture
  has pinned build entrypoints"`. Static checks passed: `scripts/build_d3d11_probe_exe.zsh`,
  `zsh -n scripts/run_macos_runtime_cli_smoke.zsh`, Ruby YAML parsing for
  `.github/workflows/macos-runtime-cli-smoke.yml`, and `git diff --check`.
  Dynamic local smoke passed through the public CLI path with
  `KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL=false`,
  `KONYAK_MACOS_RUNTIME_CLI_SMOKE_WORK_ROOT=.dart_tool/konyak/macos-runtime-visible-smoke-final`,
  and the Windows-runner-built D3D12 executable at
  `.dart_tool/konyak/windows-d3d12-fixture-local-display/konyak_d3d12_minimal.exe`;
  it ran DXVK and DXMT D3D11 visible samples, selected `d3dmetal` for the
  D3D12 visible sample on the local GPTK/D3DMetal-capable runtime, wrote
  `KONYAK_D3D11_PROBE_OK` sentinels for both D3D11 bottles and
  `KONYAK_D3D12_MINIMAL_SAMPLE_OK` for the D3D12 bottle, and printed
  `macOS runtime CLI smoke passed.` Required gates passed: `just
  verify-governance`, `just verify-safety`, `just format-check`, `just lint`,
  and `just flutter-test`. Sub-agent workstream isolation was used: explorer
  agent `019f0797-dc57-7e52-84ca-b871d343f545` audited the current probe/sample
  contracts, confirmed the parent change set as the smallest safe scope, and
  identified runtime-submodule direct Wine diagnostics as separate follow-up
  work if product policy later requires those jobs to stop using device-only
  probes.

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
