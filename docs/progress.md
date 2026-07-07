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

- Timestamp: 2026-07-07 19:45 JST
- State: `blocked`
- Branch: `task/dlss-metalfx-render-proof`; this snapshot is committed at the
  branch tip for the DLSS/MetalFX proof harness.
- Active work: DLSS/MetalFX rendering proof harness.
- Related TODO: `docs/todo.md` Next Tasks, "Capture end-to-end DLSS/MetalFX
  rendering proof with a redistributable or user-provided DLSS-capable Windows
  program."
- Purpose: add a maintained minimal Windows-side DLSS/MetalFX probe and
  Konyak-owned smoke path that can prove the public `run-program --json`
  D3DMetal launch contract with user-provided or transient DLSS/GPTK payloads,
  without redistributing proprietary runtime inputs.
- Workstream separation:
  - Investigation: confirm the existing D3D12 visible sample, GPTK/D3DMetal
    import contract, DLSS/MetalFX environment gating, and vendor-payload
    constraints before changing code.
  - Implementation: add the smallest fixture, script, workflow, and docs needed
    for a repeatable user-provided-payload proof through Konyak's public CLI.
  - Audit: rerun focused tests and required gates independently after the
    implementation, and record any external-payload blocker as unconfirmed
    rather than claiming dynamic DLSS/MetalFX proof.
- Completed work:
  - Created dedicated branch `task/dlss-metalfx-render-proof`.
  - Added a failing-first Flutter contract test for the DLSS/MetalFX fixture,
    build script, workflow, smoke entry point, and proof documentation.
  - Added `tests/fixtures/windows/dlss_metalfx_preflight`, a Windows x64 MSVC
    D3D12 preflight fixture that verifies D3D12 presentation,
    `D3DM_ENABLE_METALFX`, and `nvngx.dll` / `nvapi64.dll` loading without
    bundling NVIDIA DLSS SDK binaries.
  - Added `scripts/build_dlss_metalfx_preflight_windows.ps1` and
    `.github/workflows/windows-dlss-metalfx-preflight-build.yml` so CI can
    build the redistributable fixture on Windows.
  - Added `scripts/run_macos_dlss_metalfx_cli_smoke.zsh`, a maintained public
    `run-program --json` smoke path for user-provided GPTK/D3DMetal and
    user-provided DLSS-capable Windows programs.
  - Added `docs/dlss-metalfx-render-proof.md` documenting what the preflight
    fixture proves, what it does not prove, and the evidence required for the
    remaining end-to-end rendering proof.
  - Built the preflight fixture on GitHub Actions, downloaded the Windows
    artifact, and ran the public CLI smoke locally on macOS 26.5.1 with Apple
    GPTK 4.0 beta 1.
  - The dynamic preflight reached `run-program --json`, imported GPTK4,
    selected D3DMetal, emitted `D3DM_ENABLE_METALFX=1`, and loaded
    `nvngx.dll`.
  - The preflight failed before D3D12 presentation because `LoadLibraryW` for
    `nvapi64.dll` returned false with `GetLastError=1114`
    (`ERROR_DLL_INIT_FAILED`). No end-to-end DLSS/MetalFX rendering proof is
    claimed.
- Remaining work: investigate why the current GPTK4 D3DMetal runtime path
  cannot initialize `nvapi64.dll` under Konyak's public `run-program --json`
  launch contract, then rerun `scripts/run_macos_dlss_metalfx_cli_smoke.zsh`
  with either the preflight fixture or a real DLSS-capable Windows program.
- Next action: open a focused runtime investigation against the captured
  `nvapi64.dll` initialization failure. Use the same smoke command and compare
  against CrossOver or a known-good GPTK/D3DMetal launch path before changing
  runtime contracts.
- Verification performed:
  - `git status --short --branch` showed local `main` clean and aligned with
    `origin/main` before branching.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/windows_dlss_metalfx_preflight_fixture_test.dart'`
    first failed because the fixture files did not exist, then passed after
    implementation.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_macos_dlss_metalfx_cli_smoke.zsh && git diff --check && just flutter-format-check && just flutter-analyze && just flutter-test'`
    passed; Flutter test reported 471 tests passed.
  - `nix develop -c zsh -lc './scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
    returned exit code `64` as expected when
    `KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE` was not supplied.
  - `nix develop -c zsh -lc 'just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
    passed; `just cli-test` reported 385 tests passed.
  - GitHub Actions run `28860032171` passed
    `Windows DLSS MetalFX Preflight Build` for branch
    `task/dlss-metalfx-render-proof`; the downloaded artifact was
    `.dart_tool/konyak/windows-dlss-metalfx-preflight/konyak_dlss_metalfx_preflight.exe`.
  - Local dynamic preflight command:
    `nix develop -c zsh -lc 'KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE="$PWD/.dart_tool/konyak/windows-dlss-metalfx-preflight/konyak_dlss_metalfx_preflight.exe" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=4 ./scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
    failed as expected for the current runtime state after writing structured
    evidence:
    `marker=KONYAK_DLSS_METALFX_PREFLIGHT_FAILED`,
    `D3DM_ENABLE_METALFX=1`, `D3DM_SUPPORT_DXR=1`, `nvngx_loaded=true`,
    `nvapi64_loaded=false`, `nvapi64_error=1114`,
    `d3d12_presented=false`.
  - Dynamic evidence paths:
    `.dart_tool/konyak/macos-dlss-metalfx-smoke/logs/dlss-metalfx-run.cxlog`
    and
    `.dart_tool/konyak/macos-dlss-metalfx-smoke/logs/preflight-evidence.txt`.
