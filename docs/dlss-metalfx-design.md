# DLSS Powered By MetalFX Design

This document defines the first Konyak design for a macOS bottle setting that
mirrors CrossOver's DLSS powered by MetalFX behavior.

## Scope

- Runtime target: arm64 macOS running the Konyak-managed CrossOver-derived Wine
  runtime
- UI target: Bottle Configuration, macOS-only Metal graphics controls
- Open verification: rendered DLSS/MetalFX proof remains a user-provided or
  local runtime verification item.

## External Behavior To Match

CrossOver Mac 26 documents DLSS as "DLSS powered by MetalFX". The setting only
takes effect when DLSS is enabled inside the game and only applies to D3DMetal
and DXMT. Some games benefit from it and some do not.

Apple documents MetalFX as Metal-native upscaling support with spatial and
temporal upscaling modes. Konyak must describe the feature as a DLSS-to-MetalFX
compatibility path, not as NVIDIA RTX DLSS.

References:

- CodeWeavers: <https://support.codeweavers.com/en_US/advanced-settings-in-crossover-mac-26>
- Apple MetalFX: <https://developer.apple.com/documentation/metalfx>

## Resolved Enablement Signals

Konyak implements the DLSS/MetalFX bottle setting by adding backend-specific
launch environment variables only when the selected backend can consume them.

| Backend | Launch condition | Environment variable | References |
|---|---|---|---|
| DXMT | macOS bottle, DXMT selected, `dlssMetalFx == true` | `DXMT_ENABLE_NVEXT=1` | DXMT source `src/dxgi/dxgi.cpp`: <https://github.com/3Shain/dxmt/blob/main/src/dxgi/dxgi.cpp>; DXMT Wiki, Vendor Extensions: <https://github.com/3Shain/dxmt/wiki/Vendor-Extensions> |
| D3DMetal | macOS bottle, D3DMetal selected, `dlssMetalFx == true`, detected macOS major version is 16 or newer | `D3DM_ENABLE_METALFX=1` | CodeWeavers CrossOver Mac 26 advanced settings: <https://support.codeweavers.com/en_US/advanced-settings-in-crossover-mac-26>; GPTK 3.0 guide: <https://mybyways.com/blog/updating-crossover-to-gameporting-toolkit-3-0>; GPTK/MetalFX notes: <https://github.com/lynkos/blog/blob/main/_posts/2025-03-19-play-windows-games.md>; MacPorts `d3dmetal` Portfile: <https://github.com/macports/macports-ports/blob/master/devel/d3dmetal/Portfile> |

The D3DMetal gate intentionally follows the CrossOver 26.1/GPTK 3.0 behavior
that only treats `D3DM_ENABLE_METALFX=1` as applicable on macOS 16 or newer.
Konyak stores the same references near the launch-environment code so future
runtime changes can be audited against the source of the signal.

## Existing Konyak Runtime Shape

Konyak already has most of the required runtime shape:

- GPTK/D3DMetal is an optional user-imported component, isolated under
  `components/gptk-d3dmetal`.
- GPTK/D3DMetal imports validate `nvapi64.dll`, `nvngx.dll`, `nvapi64.so`, and
  `nvngx.so`.
- DXMT component packaging builds and requires `nvapi64.dll` and `nvngx.dll`.
- macOS D3DMetal launch plans add D3DMetal component Windows and Unix paths and
  set `CX_APPLEGPTK_LIBD3DSHARED_PATH`.
- D3DMetal launch plans currently include `nvapi64,nvngx` in
  `WINEDLLOVERRIDES`.
- DXMT launch plans currently select DXMT D3D10/D3D11 DLLs, but do not model a
  separate DLSS/MetalFX setting.

The implementation must preserve the existing runtime ownership rule: parent
repository code consumes complete runtime-owner-produced or explicitly imported
runtime stacks. It must not fetch, generate, or overlay proprietary D3DMetal,
MetalFX, or NVIDIA shim payloads.

## Product Contract

MacOS bottles support this runtime setting:

- Domain name: `dlssMetalFx`
- User-facing label: `DLSS / MetalFX`
- User-facing meaning: enable the DLSS compatibility shim that routes supported
  game DLSS requests through MetalFX when the selected backend supports it.
- Default: `false`
- Persistence scope: Konyak bottle metadata, beside other runtime settings.
- Platform scope: macOS only. Linux must not expose this setting.
- Backend scope: enabled only when D3DMetal or DXMT is selected and the selected
  backend has the required shim files.

This setting does not force game DLSS on. The game must still expose and enable
DLSS in its own settings.

## Availability Rules

The UI control should be enabled only when all of these are true:

- Platform is macOS.
- Runtime capabilities have loaded.
- The bottle is using D3DMetal or DXMT.
- The selected backend reports the required `nvapi64` and `nvngx` files.

When unavailable, the control should remain visible in the Metal section only if
that matches the surrounding Konyak configuration style; otherwise hide it with
the rest of the backend-specific unavailable controls. Do not show it on Linux.

## CLI And Data Contract

Extend the existing bottle runtime settings contract:

- `packages/konyak_cli` domain model: add `dlssMetalFx`.
- Storage parser/writer: persist and validate a boolean field.
- Flutter bottle summary parser: require the boolean once the CLI emits it.
- Flutter summary model: add `dlssMetalFx` and `withDlssMetalFx`.
- `set-runtime-settings --json`: accept and emit the field.

Compatibility expectation:

- Existing bottle metadata without `dlssMetalFx` should parse as `false`.
- Existing Flutter/CLI JSON tests must explicitly cover the legacy default.

## Run Planning Contract

The run planner must treat the setting as backend-specific launch state:

- D3DMetal selected and `dlssMetalFx == true`:
  - keep D3DMetal paths and `CX_APPLEGPTK_LIBD3DSHARED_PATH`;
  - ensure `nvapi64` and `nvngx` are active through the D3DMetal component;
  - apply `D3DM_ENABLE_METALFX=1` only when the detected macOS major version is
    16 or newer.
- DXMT selected and `dlssMetalFx == true`:
  - keep DXMT paths;
  - ensure `nvapi64` and `nvngx` are active through the DXMT component;
  - apply `DXMT_ENABLE_NVEXT=1`.
- DXVK, vkd3d-proton, or Wine selected:
  - ignore the setting in the launch environment;
  - preserve the persisted value so switching back to D3DMetal/DXMT restores
    the user's preference.

The launch signals are sourced from the references above. Do not add new
backend variables, registry keys, or payload mutation paths without updating
this table and the nearby code references.

## Runtime Proof And CI Limits

Konyak currently claims setting persistence, UI exposure, and public run-plan
environment injection. It does not claim that an arbitrary game will render
through MetalFX, because that requires a DLSS-capable Windows program and the
selected runtime payloads.

When a redistributable or user-provided DLSS-capable test program is available,
capture dynamic evidence through Konyak's public execution path:

- command: `dart run bin/konyak.dart run-program <bottle> --program <path> --json`
- bottle id and path
- selected backend: D3DMetal or DXMT
- runtime root and GPTK/D3DMetal component path
- full argv and environment from the run plan
- process IDs and exit status
- Konyak launch log and Wine stdout/stderr
- loaded image evidence for `nvapi64`, `nvngx`, and the selected Metal backend
- Metal HUD or equivalent evidence showing the MetalFX path when practical

At least one DLSS-capable test program or maintained smoke path should
demonstrate that enabling the setting changes the relevant runtime state
compared with the setting disabled. If no redistributable DLSS-capable program
can be used in CI, record the local-only proof and document the CI limitation in
`docs/progress.md`.

## CI And Runtime Workflow

If local smoke verification proves a maintained runtime execution path, mirror
the closest practical path in GitHub Actions. Keep rerun units narrow:

- do not combine Wine runtime build, GPTK/D3DMetal import smoke, DXMT build,
  package publishing, and app smoke into one monolithic job;
- downstream smoke jobs must consume uploaded runtime artifacts rather than
  rebuilding the CrossOver-derived Wine runtime.

If the DLSS/MetalFX proof needs a proprietary or nonredistributable game, do not
add that game to CI. Instead, add a maintained local smoke script and document
why CI cannot mirror it.

## Non-Goals

- Do not implement NVIDIA RTX DLSS on Apple GPUs.
- Do not expose this setting on Linux.
- Do not download or package proprietary GPTK/D3DMetal payloads from the parent
  repository.
- Do not silently enable DLSS/MetalFX whenever `nvngx` exists; users need a
  reversible bottle-level setting.
- Do not claim frame generation support unless dynamic proof specifically
  confirms it through the same public Konyak execution path.
