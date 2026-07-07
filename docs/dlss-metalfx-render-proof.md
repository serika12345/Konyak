# DLSS/MetalFX Rendering Proof

This document defines Konyak's maintained DLSS/MetalFX proof path. The goal is
to prove the public Konyak CLI launch contract with a redistributable or
user-provided DLSS-capable Windows program, while keeping Apple GPTK/D3DMetal
and NVIDIA DLSS payloads out of Konyak release artifacts.

## Scope

The proof must use:

- `run-program --json` as the application-owned execution path.
- A Konyak-managed macOS Wine runtime installed from a runtime-owner-produced
  source manifest.
- A user-provided or transient GPTK/D3DMetal source imported through
  `install-gptk-wine --json`.
- D3DMetal runtime settings with `dlssMetalFx` enabled.
- Konyak run logs, Wine logs, runtime component paths, process exit status, and
  a sentinel or equivalent program-owned evidence file.

Do not add proprietary game payloads, Apple GPTK/D3DMetal payloads, NVIDIA DLSS
DLLs, or Streamline binary release artifacts to this repository or to Konyak
release assets.

## Maintained Entrypoints

The reusable local smoke script is:

```sh
nix develop -c zsh -lc './scripts/run_macos_dlss_metalfx_cli_smoke.zsh'
```

Required input:

```sh
KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE=/path/to/program.exe
KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE=/path/to/Game_Porting_Toolkit.dmg
```

Optional input:

```sh
KONYAK_MACOS_DLSS_METALFX_SMOKE_ARGUMENTS='--frames 180 --require-metalfx-env --require-nv-shims'
KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION=auto
KONYAK_MACOS_DLSS_METALFX_SMOKE_EXPECTED_EXIT_CODE=0
KONYAK_MACOS_DLSS_METALFX_SMOKE_SENTINEL_FILE=konyak-dlss-metalfx-preflight-ok.txt
KONYAK_MACOS_DLSS_METALFX_SMOKE_SENTINEL_MARKER=KONYAK_DLSS_METALFX_PREFLIGHT_OK
```

The script installs the macOS runtime, imports GPTK/D3DMetal when requested,
creates a fresh smoke bottle, enables D3DMetal plus `dlssMetalFx`, runs the
program through `run-program --json`, and records evidence under:

```text
.dart_tool/konyak/macos-dlss-metalfx-smoke/logs/
```

The proof requires macOS 16 or newer by default because Konyak only emits
`D3DM_ENABLE_METALFX=1` on that host capability gate. Set
`KONYAK_MACOS_DLSS_METALFX_SMOKE_ALLOW_UNSUPPORTED_HOST=true` only for harness
diagnostics that do not claim DLSS/MetalFX proof.

## Preflight Fixture

Konyak includes a redistributable Windows fixture source under:

```text
tests/fixtures/windows/dlss_metalfx_preflight/
```

Build it on Windows with:

```powershell
./scripts/build_dlss_metalfx_preflight_windows.ps1
```

The fixture verifies that the launch process can:

- Create a D3D12 device and present frames.
- Observe `D3DM_ENABLE_METALFX=1` when required.
- Load `nvngx.dll` and `nvapi64.dll` when required, either before D3D12 setup
  or after D3D12 presentation.
- Write `C:\konyak-dlss-metalfx-preflight-ok.txt`.
- Write `C:\konyak-dlss-metalfx-preflight-evidence.txt` with the observed
  D3DMetal, DXR, GPTK, and NVIDIA shim state.

Use the default `--probe-nv-shims-before-d3d12` mode to catch missing or
unloadable NVIDIA shims before rendering. Use
`--probe-nv-shims-after-d3d12` only as a diagnostic comparison when
investigating whether a GPTK/D3DMetal payload requires D3D12 initialization
before its NVIDIA shim DLLs can attach. The evidence file records
`nv_shim_probe_phase`.

This fixture is a preflight harness, not a DLSS SDK integration. Passing it
proves the Konyak D3DMetal/DLSS MetalFX launch contract and shim availability.
It does not prove that DLSS Super Resolution or Frame Generation executed.

## End-to-End DLSS/MetalFX Proof

To satisfy the roadmap item, run the smoke script with a user-provided
DLSS-capable Windows program that actually enables DLSS in the application. The
program should terminate on its own or expose deterministic arguments that make
it render, enable DLSS, write a sentinel, and exit.

The handoff must record:

- Exact command and timestamp.
- Host macOS version and machine.
- Runtime source manifest path and runtime root.
- GPTK/D3DMetal source path and requested version.
- Windows program path, argv, and expected exit code.
- Konyak `run-program --json` output.
- Konyak run log containing `D3DM_ENABLE_METALFX=1`,
  `D3DM_SUPPORT_DXR=1`, `WINEDLLOVERRIDES=dxgi,d3d11,d3d12,nvapi64,nvngx=n,b`,
  and `CX_APPLEGPTK_LIBD3DSHARED_PATH=...`.
- Program sentinel or equivalent app-owned evidence.
- Metal HUD, Metal capture, or program log evidence where practical.

If the only available executable is the Konyak preflight fixture, report the
result as launch-contract preflight evidence, not as end-to-end DLSS rendering
proof.
