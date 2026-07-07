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

- Timestamp: 2026-07-07 22:54 JST
- State: `paused`
- Branch: `task/dlss-metalfx-render-proof`; latest committed investigation
  input is `b94b0af`.
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
  - Continued GPTK4 investigation through the public `run-program --json`
    path. With `--require-nv-shims` removed, GPTK4 still returned
    `nvapi64_error=1114` but presented D3D12 frames successfully, proving the
    GPTK4 failure is scoped to the NVIDIA shim attach path rather than the
    D3D12/D3DMetal present path.
  - Re-ran the same GPTK4 bottle with `dlssMetalFx=false`; `D3DM_ENABLE_METALFX`
    was absent and `nvapi64.dll` still failed with `GetLastError=1114`, so the
    MetalFX environment switch itself is not the failure trigger.
  - Added a preflight fixture option to compare NVIDIA shim probe timing before
    D3D12 setup versus after D3D12 presentation.
  - Built the updated fixture on GitHub Actions and downloaded artifact
    `.dart_tool/konyak/windows-dlss-metalfx-preflight-2a79fc5/konyak_dlss_metalfx_preflight.exe`
    with SHA-256
    `2d2239c32ffe4ce64341e70504b4224af297552a829696e1c0cc03fcf4e13316`.
  - Re-ran GPTK4 with `--probe-nv-shims-after-d3d12`; D3D12 presentation
    succeeded first, but `nvapi64.dll` still failed with `GetLastError=1114`.
    This rules out D3D12 initialization order as the cause.
  - Ran the same after-D3D12 fixture against GPTK3; `nvngx.dll` and
    `nvapi64.dll` both loaded and the smoke passed. This confirms the new
    fixture mode and Konyak public CLI path are viable, and the failure is
    GPTK4-specific in the current runtime stack.
  - Tried public-CLI program-setting overrides that add `nvapi` to
    `WINEDLLOVERRIDES` and that force the NVIDIA shims to `builtin`; both kept
    the same GPTK4 `nvapi64_error=1114` result.
  - Inspected a user-provided CrossOver 26.1 bundle; it carries a GPTK3-era
    `lib64/apple_gptk` payload with D3DMetal 3.0, not GPTK4 beta 1.
  - Inspected a second user-provided CrossOver 26.2 bundle
    (`26.2.0.39821`); it also carries D3DMetal 3.0 in
    `Contents/SharedSupport/CrossOver/lib64/apple_gptk`, matching the GPTK4
    beta 1 Read Me note that pre-built tools may still carry the prior
    D3DMetal early in the macOS 26 Tahoe beta period.
  - Confirmed the GPTK4 beta 1 Read Me explicitly instructs CrossOver users to
    replace the CrossOver bundle's
    `Contents/SharedSupport/CrossOver/lib64/apple_gptk` `external` and `wine`
    directories with the GPTK4 beta 1 `redist/lib` input.
    The same Read Me separately instructs users to rename
    `nvngx-on-metalfx` to `nvngx` and copy both `nvngx.dll` and
    `nvapi64.dll` into the Wine prefix `drive_c/windows/system32`.
  - Created a repo-local diagnostic CrossOver bundle copy, replaced only that
    copy's `apple_gptk` payload with the user-provided GPTK4 beta 1
    `redist/lib` input, renamed `nvngx-on-metalfx` to `nvngx`, removed
    quarantine where possible, and ad-hoc re-signed the copied bundle after
    macOS reported the modified copy as damaged due to sealed resource
    changes. The original user-provided CrossOver bundle was not modified.
  - After GUI approval of the copied app, created an isolated CrossOver private
    bottle under `.dart_tool/konyak/crossover-gptk4-swap/Bottles` and copied
    the preflight executable into that bottle's `C:\konyak`.
  - Ran the copied CrossOver with the copied GPTK4 `apple_gptk` payload,
    explicit D3DMetal/DLSS environment, and the bottle's generated 1 KiB
    `system32` NVIDIA shim stubs. The preflight passed with D3D12 presentation
    and both shim names loadable, but this did not prove GPTK4 NVIDIA shim
    attach because both `nvapi64.dll` and `nvngx.dll` were CrossOver-generated
    stubs with SHA-256
    `76935dbf9665ab75549e61de1c912dd41f34c81bbf6cd985386717e3a2bb439b`.
  - Replaced the isolated bottle's `drive_c/windows/system32/nvapi64.dll` and
    `nvngx.dll` with the copied GPTK4 beta 1 DLLs, matching the Read Me's
    prefix-copy instruction. The copied hashes were
    `0018446a3d5289a29db9bc1f3dc2beb5c59e83c036ca02d9b3b2db7779e92424`
    for `nvapi64.dll` and
    `ac90c3fbd969488d0e7b5e0a141f19736e8a3d330b484438c44779c4ecf2b152`
    for `nvngx.dll`.
  - Re-ran the copied CrossOver/GPTK4 path after the Read Me prefix-copy step.
    D3D12 presentation succeeded and `nvngx.dll` loaded from
    `C:\windows\system32\nvngx.dll`, but `nvapi64.dll` failed from
    `C:\windows\system32\nvapi64.dll` with `GetLastError=1114`. The copied
    CrossOver diagnostic therefore reproduces the same GPTK4 `nvapi64.dll`
    attach failure seen through Konyak's public CLI path.
  - Compared GPTK4 and GPTK3 Wine traces: both log a benign
    `find_builtin_dll` warning while looking for `nvapi.dll` for
    `nvapi64.dll`, but GPTK3's `nvapi64.dll` completes `PROCESS_ATTACH` while
    GPTK4's `nvapi64.dll` immediately calls `PROCESS_DETACH` and Wine reports
    `Initialization of L"nvapi64.dll" failed`.
  - Inspected `thetheoryofR/toolkit4`; its documented flow differs from the
    earlier Apple Read Me reproduction by assuming a real Steam bottle,
    CrossOver bottle D3DMetal/DLSS toggles, `D3DM_MTL4=1`,
    `MTL_HUD_ENABLED=1`, and macOS 27.0 or later. On this machine,
    `system_profiler` reports `Metal Support: Metal 4`, but
    `toolkit4 check` fails because the OS is macOS 26.5.1 and no `Steam`
    bottle exists under the default CrossOver bottle path.
  - Re-ran the copied CrossOver/GPTK4 diagnostic with the toolkit4-style
    `D3DM_MTL4=1` and `MTL_HUD_ENABLED=1` environment added. D3D12
    presentation still succeeded and `nvngx.dll` still loaded, but
    `nvapi64.dll` still failed with `GetLastError=1114`, so the Metal 4 flag
    does not change the maintained preflight failure on this host.
  - Recorded the product support conclusion in `docs/todo.md`,
    `docs/dlss-metalfx-design.md`, and `docs/dlss-metalfx-render-proof.md`:
    GPTK4 D3DMetal works for the D3DMetal/D3D12 render path, but GPTK4 plus
    DLSS/MetalFX is treated as requiring macOS 27 and is not supported for now.
  - Recorded the maintainer constraint: the primary maintainer must keep
    macOS 26 available while developing another Rosetta 2 based project, so the
    primary maintainer will not implement GPTK4 plus DLSS/MetalFX support until
    that host constraint changes.
  - Removed local external-input paths from the GPTK import smoke script and
    documentation history. Historical evidence now refers to user-provided
    CrossOver bundles and GPTK DMG inputs instead of concrete local paths.
  - Changed `scripts/run_macos_gptk_import_cli_smoke.zsh` so GPTK3 and GPTK4
    sources must be supplied explicitly through `KONYAK_GPTK3_SOURCE_PATH` and
    `KONYAK_GPTK4_SOURCE_PATH`; the script no longer defaults to any local
    Downloads path.
- Remaining work: no active GPTK4 plus DLSS/MetalFX implementation is planned.
  Future GPTK4 work should remain limited to D3DMetal import, runtime layout,
  and D3D12/D3DMetal render-path validation until macOS 27 is available in the
  supported development and verification matrix.
- Next action: pause GPTK4 plus DLSS/MetalFX work. Continue only if the project
  support matrix changes to include macOS 27, or if a separate task asks for
  D3DMetal-only GPTK4 validation.
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
    `nix develop -c zsh -lc 'KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE="$PWD/.dart_tool/konyak/windows-dlss-metalfx-preflight/konyak_dlss_metalfx_preflight.exe" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE="$KONYAK_GPTK4_SOURCE_PATH" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=4 ./scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
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
  - `nix develop -c zsh -lc 'KONYAK_MACOS_DLSS_METALFX_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk4-no-shim-require" KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE="$PWD/.dart_tool/konyak/windows-dlss-metalfx-preflight/konyak_dlss_metalfx_preflight.exe" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE="$KONYAK_GPTK4_SOURCE_PATH" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=4 KONYAK_MACOS_DLSS_METALFX_SMOKE_ARGUMENTS="--frames 60 --require-metalfx-env" KONYAK_MACOS_DLSS_METALFX_SMOKE_WAIT_SECONDS=20 ./scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
    passed and wrote
    `.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk4-no-shim-require/logs/preflight-evidence.txt`
    with `marker=KONYAK_DLSS_METALFX_PREFLIGHT_OK`,
    `d3d12_presented=true`, `nvngx_loaded=true`,
    `nvapi64_loaded=false`, and `nvapi64_error=1114`.
  - Manual public CLI comparison against the same GPTK4 smoke bottle with
    `dlssMetalFx=false` wrote
    `.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk4-dlss-off/logs/preflight-evidence.txt`
    with `D3DM_ENABLE_METALFX=` and the same `nvapi64_error=1114` failure.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/windows_dlss_metalfx_preflight_fixture_test.dart'`
    passed after adding the after-D3D12 probe option.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_macos_dlss_metalfx_cli_smoke.zsh && git diff --check'`
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check && just flutter-analyze && just flutter-test'`
    passed; Flutter test reported 470 tests passed.
  - `nix develop -c zsh -lc 'just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
  - GitHub Actions run `28862185392` passed
    `Windows DLSS MetalFX Preflight Build` for commit `2a79fc5`.
  - GitHub Actions run `28862185434` passed `Konyak Verify` for commit
    `2a79fc5`.
  - `nix develop -c zsh -lc 'KONYAK_MACOS_DLSS_METALFX_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk4-after-d3d12" KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE="$PWD/.dart_tool/konyak/windows-dlss-metalfx-preflight-2a79fc5/konyak_dlss_metalfx_preflight.exe" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE="$KONYAK_GPTK4_SOURCE_PATH" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=4 KONYAK_MACOS_DLSS_METALFX_SMOKE_ARGUMENTS="--frames 60 --require-metalfx-env --require-nv-shims --probe-nv-shims-after-d3d12" KONYAK_MACOS_DLSS_METALFX_SMOKE_WINEDEBUG="+loaddll,+module,+seh" KONYAK_MACOS_DLSS_METALFX_SMOKE_WAIT_SECONDS=20 ./scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
    failed as expected for GPTK4 and wrote
    `.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk4-after-d3d12/logs/preflight-evidence.txt`
    with `nv_shim_probe_phase=after_d3d12`, `d3d12_presented=true`,
    `nvngx_loaded=true`, `nvapi64_loaded=false`, and `nvapi64_error=1114`.
  - `nix develop -c zsh -lc 'KONYAK_MACOS_DLSS_METALFX_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk3-after-d3d12" KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE="$PWD/.dart_tool/konyak/windows-dlss-metalfx-preflight-2a79fc5/konyak_dlss_metalfx_preflight.exe" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE="$KONYAK_GPTK3_SOURCE_PATH" KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=3 KONYAK_MACOS_DLSS_METALFX_SMOKE_ARGUMENTS="--frames 60 --require-metalfx-env --require-nv-shims --probe-nv-shims-after-d3d12" KONYAK_MACOS_DLSS_METALFX_SMOKE_WINEDEBUG="+loaddll,+module,+seh" KONYAK_MACOS_DLSS_METALFX_SMOKE_WAIT_SECONDS=20 ./scripts/run_macos_dlss_metalfx_cli_smoke.zsh'`
    passed and wrote
    `.dart_tool/konyak/macos-dlss-metalfx-smoke-gptk3-after-d3d12/logs/preflight-evidence.txt`
    with `nvapi64_loaded=true`, `nvapi64_error=0`, and
    `d3d12_presented=true`.
  - Manual public CLI overrides for
    `WINEDLLOVERRIDES=dxgi,d3d11,d3d12,nvapi,nvapi64,nvngx=n,b` and
    `WINEDLLOVERRIDES=dxgi,d3d11,d3d12=n,b;nvapi64,nvngx=b` both preserved the
    GPTK4 `nvapi64_error=1114` failure.
  - Extracting the user-provided GPTK4 beta 1 Read Me confirmed the CrossOver
    `apple_gptk` replacement step and the separate DLSS/MetalFX
    `nvngx-on-metalfx` rename plus prefix `system32` copy step.
  - Creating a repo-local copy of the user-provided CrossOver bundle followed
    by GPTK4 `redist/lib` replacement produced a copied app with D3DMetal
    `4.0b1`; SHA-256 was
    `0018446a3d5289a29db9bc1f3dc2beb5c59e83c036ca02d9b3b2db7779e92424`
    for `nvapi64.dll`,
    `ac90c3fbd969488d0e7b5e0a141f19736e8a3d330b484438c44779c4ecf2b152`
    for `nvngx.dll`, and
    `66005073540dc91001ea11685160a71e302bfd79c2ee7b9fe5be560ae17621e2`
    for `libd3dshared.dylib`.
  - Code-signature verification passed for the original user-provided
    CrossOver bundle. The modified copy initially failed with `a sealed
    resource is missing or invalid`, explaining macOS's damaged-app dialog;
    ad-hoc signing the copied app made verification pass. The user then
    approved the copied app through the GUI, allowing CrossOver's `cxbottle`
    tooling to run.
  - Copied CrossOver diagnostic bottle creation passed under isolated
    `CX_BOTTLE_PATH=.dart_tool/konyak/crossover-gptk4-swap/Bottles` with
    `cxbottle --create --scope private --bottle konyak-gptk4-preflight --template win10_64`.
  - Copied CrossOver baseline preflight with generated 1 KiB `system32`
    NVIDIA shims passed with `marker=KONYAK_DLSS_METALFX_PREFLIGHT_OK`,
    `d3d12_presented=true`, `nvngx_loaded=true`, and `nvapi64_loaded=true`.
    Evidence was copied to
    `.dart_tool/konyak/crossover-gptk4-swap/logs/baseline-preflight-evidence.txt`.
  - Copied CrossOver preflight after replacing `system32/nvapi64.dll` and
    `system32/nvngx.dll` with GPTK4 beta 1 DLLs failed with
    `marker=KONYAK_DLSS_METALFX_PREFLIGHT_FAILED`, `d3d12_presented=true`,
    `nvngx_loaded=true`, `nvapi64_loaded=false`, and `nvapi64_error=1114`.
    Evidence was copied to
    `.dart_tool/konyak/crossover-gptk4-swap/logs/gptk4-system32-preflight-evidence.txt`.
  - Targeted Wine trace comparison showed GPTK4 and GPTK3 both emit the
    `find_builtin_dll` warning for `nvapi64.dll`, but only GPTK4 logs
    `Initialization of L"nvapi64.dll" failed` during `PROCESS_ATTACH`.
  - `bash .dart_tool/konyak/toolkit4-src/gptk4.txt check` returned
    `toolkit4_check_rc=1` because the host is macOS 26.5.1 while toolkit4
    requires macOS 27.0 or later, and the default `Steam` CrossOver bottle was
    not present.
  - Copied CrossOver preflight with GPTK4 beta 1 DLLs plus toolkit4-style
    `D3DM_MTL4=1` and `MTL_HUD_ENABLED=1` failed with
    `marker=KONYAK_DLSS_METALFX_PREFLIGHT_FAILED`, `d3d12_presented=true`,
    `nvngx_loaded=true`, `nvapi64_loaded=false`, and `nvapi64_error=1114`.
    Evidence was copied to
    `.dart_tool/konyak/crossover-gptk4-swap/logs/gptk4-mtl4-preflight-evidence.txt`.
  - `nix develop -c zsh -lc 'just verify-governance && just verify-safety && just format-check && just lint'`
    passed after recording the CrossOver/GPTK4 diagnostic results and GPTK4
    plus DLSS/MetalFX support decision.
  - Repository grep for maintainer-specific and external-input local paths
    returned no matches in docs and scripts.
  - `zsh -n scripts/run_macos_gptk_import_cli_smoke.zsh`, `git diff --check`,
    `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed after sanitizing the path history.
  - Repository grep confirmed docs and scripts no longer contain local
    CrossOver/GPTK DMG input paths. `scripts/run_macos_gptk_import_cli_smoke.zsh`
    passed syntax check and exits `64` when GPTK3/GPTK4 source inputs are not
    supplied. `git diff --check`, submodule `git diff --check`,
    `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed after removing local-dependent external input examples.
