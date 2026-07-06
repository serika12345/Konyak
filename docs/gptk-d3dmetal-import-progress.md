# GPTK/D3DMetal Import Progress

This file tracks the dedicated GPTK/D3DMetal import workstream. It is the
source of truth for milestone scope, PR gates, current status, and handoff
notes for GPTK 3 and GPTK 4 import compatibility.

Use `docs/todo.md` only as the top-level roadmap pointer. Use
`docs/progress.md` for the repository-wide current work snapshot.

## Current Snapshot

- Timestamp: 2026-07-06 17:44 JST
- State: `paused`
- Branch: `task/gptk4-parent-import-variant`
- Pull request: https://github.com/serika12345/Konyak/pull/37. Previous parent
  PR https://github.com/serika12345/Konyak/pull/36 was merged into parent
  `main` as `4e56d49`; parent PR https://github.com/serika12345/Konyak/pull/35
  was merged as `0afa99f`.
- Runtime submodule: no runtime changes planned for G3-P1. Previous runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 was merged into
  runtime `main` as `eedc190`.
- Active gate: `G3-P1 GPTK4 Parent Import Variant`
- Purpose: accept the GPTK4 parent import payload variant that lacks
  `atidxx64.*`, while keeping GPTK3 validation strict and recording the
  detected GPTK version in the public import result.
- Completed work: created branch `task/gptk4-parent-import-variant`; added
  GPTK4-without-`atidxx64.*` parent CLI/importer coverage; kept GPTK3
  validation strict; split GPTK validation and copy requirements by detected
  version; removed `atidxx64.*` from the active runtime completeness contract;
  preserved `nvngx-on-metalfx.*` source normalization into canonical installed
  `nvngx.*` names; added detected GPTK version to public import JSON; pushed
  implementation commit `bb00c94`; opened draft PR #37.
- Decision: G3-P1 is parent CLI/importer work only. Runtime submodule import
  scripts and smoke contract remain G3-P2.
- Remaining work: review PR #37. Apple GPTK 4.0 beta 1 DMG proof remains
  pending outside this fixture-based parent gate.
- Next action: review PR #37. If no changes are requested, merge it, then
  continue to G3-P2 for runtime submodule import and smoke contract updates.
- Verification so far:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart test/cli_contract_runtime_process_update_test.dart test/cli_app_runtime_json_test.dart test/runtime_platform_definition_type_fronts_test.dart'`
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/test/cli_contract_runtime_install_test.dart && cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart --plain-name "install-gptk-wine imports GPTK4 payloads without atidxx64"'`
    passed.
  - `nix develop -c zsh -lc 'just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.

## Status Key

- `planned`: gate is defined but not started.
- `in_progress`: gate is actively being implemented.
- `paused`: work has stopped with a known resume point.
- `blocked`: work cannot continue without external input or state.
- `completed`: implementation, documentation, and required verification passed.
- `superseded`: scope was replaced by a later gate or design.

## Operating Rules

- Keep GPTK 3 support green before changing GPTK 4 behavior.
- Do not install Apple GPTK `d3d10.dll` or `d3d10.so` into the active
  `components/gptk-d3dmetal` layout. D3D10 uses the base Wine builtin frontend.
- Preserve existing flat CLI command compatibility. Do not remove
  `install-gptk-wine --from <path> --json`.
- Version-specific import must be explicit and schema-stable. The planned
  command option is `--gptk-version <auto|3|4>`, with omitted value treated as
  `auto` for backward compatibility.
- Any future hierarchical runtime import alias must preserve the same requested
  version semantics as the flat command: omitted version means `auto`, and
  explicit GPTK3/GPTK4 requests use the same `auto|3|4` value set.
- GPTK/D3DMetal payloads remain user-imported. Do not redistribute Apple GPTK
  payloads from Konyak release artifacts.
- Parent repository code may consume and preserve runtime-owner-produced
  artifacts and user-provided GPTK payloads, but must not synthesize missing
  runtime components to compensate for an incomplete runtime artifact.
- Runtime submodule changes must be coordinated with parent repository consumer
  contracts when import scripts, smoke checks, archive exclusion checks, source
  manifests, component paths, or CI workflows change.
- D3D10 policy: GPTK/D3DMetal is not treated as a supported D3D10 renderer.
  Konyak must prefer DXVK for D3D10 and keep a CrossOver-equivalent
  WineD3D/Vulkan fallback. A GPTK D3D10 smoke must assert the known unsupported
  signature rather than accepting bridge reachability as render proof.

## Reporting Format

This workstream adopts the reporting-rule change from PR #31,
`Add shell CLI contract registry`. GPTK milestone review packages and final
reports must carry both the decision context and the verification result.

Review package at a milestone stop:

- branch name and latest commit
- pull request URL, if opened
- completed TODO or PR Gate items
- intent behind the change
- what is now possible because of the change
- changed files summary
- verification commands and results
- design, runtime-contract, or import-contract decisions made
- remaining risks or review points
- recommended next milestone

Final reports must include:

- intent behind the change
- what is now possible because of the change
- what changed
- which commands ran
- whether verification passed
- any remaining risks

## Evidence Ledger

- Apple GPTK 3.0 DMG:
  `/Users/masato/Downloads/Game_Porting_Toolkit_3.0.dmg`
- Apple GPTK 4.0 beta 1 DMG:
  `/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg`
- CrossOver application checked:
  `/Users/masato/Documents/CrossOver.app`
- CrossOver FOSS sources checked:
  `/Users/masato/Documents/sources`
- D3D10 conclusion:
  - Apple GPTK 3.0 and GPTK 4.0 beta 1 contain `d3d10.dll` and matching
    `d3d10.so` symlinks, but CrossOver's active GPTK layout does not.
  - CrossOver FOSS `dlls/d3d10*` has no D3DMetal-specific D3D10 patch.
  - Wine's D3D10 frontend bridges through D3D11/DXGI; the selected backend is
    controlled by the D3D11/DXGI load path and overrides.
  - Konyak must not override `d3d10` for GPTK/D3DMetal. The correct override is
    `dxgi,d3d11,d3d12,nvapi64,nvngx=n,b`.
  - Actual D3D10 rendering is currently proven through DXVK. On
    2026-07-06, `dxvk-d3d10-render` passed D3D10 device creation, offscreen
    render target clear, staging copy, and readback verification against
    `dist/konyak-macos-wine-runtime-stack.tar.zst`. Diagnostic DXMT D3D10 runs
    failed with `0x80004005` before rendering, so Konyak does not claim DXMT
    D3D10 render support.
  - GPTK/D3DMetal D3D10 render/readback is not dynamically proven. On
    2026-07-06, native GPTK `dxgi`/`d3d11` diagnostic runs against the assembled
    Konyak runtime returned `0x80004005` from `D3D10CreateDevice` and
    `D3D10CreateDevice1`. A diagnostic `D3D11CreateDevice` followed by
    `QueryInterface(ID3D10Device)` returned `0x80004002`.
  - CrossOver.app D3D10 render/readback comparison passed with
    `KONYAK_D3D10_RENDER_PROBE_OK`, but `WINEDEBUG=+loaddll` showed builtin
    `dxgi.dll`, `d3d10.dll`, `d3d10core.dll`, `d3d11.dll`, `wined3d.dll`, and
    `winevulkan.dll`; the log emitted `Using the Vulkan renderer for d3d10/11
    applications.` This is not GPTK/D3DMetal proof.
  - Current Konyak runtime archives contain the base Wine builtin D3D10,
    D3D11/DXGI, WineD3D, and winevulkan payloads needed for the
    CrossOver-equivalent route. Current parent code can reach that route only
    when no DXVK, DXMT, or GPTK override is selected; it does not yet expose or
    verify it as an explicit D3D10 fallback backend.
  - CrossOver FOSS MoltenVK source contains D3D10-relevant feature
    advertisements for Apple GPUs, including source comments for
    `geometryShader` required by DXVK for D3D10, `pipelineStatisticsQuery`, and
    `shaderCullDistance`. Konyak must use a source-built CrossOver MoltenVK
    runtime component instead of adding a local WineD3D feature-gate patch or
    using the generic Khronos MoltenVK release binary.
- D3DMetal framework version metadata:
  - CrossOver.app and Apple GPTK 3.0 report
    `CFBundleShortVersionString=3.0`.
  - Apple GPTK 4.0 beta 1 reports `CFBundleShortVersionString=4.0b1`.
- GPTK 4.0 beta 1 import failure before version support:
  - Public command:
    `install-gptk-wine --from /Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg --json`
  - Exit code: `75`
  - JSON error code: `gptkWineInstallFailed`
  - Message: `GPTK/D3DMetal payload is missing atidxx64.dll.`

## Large Milestones

### G1: D3D10 GPTK Routing and Fallback Smoke

Goal: keep GPTK/D3DMetal scoped to the D3D11/D3D12/DXGI payloads it actually
supports, prove that direct GPTK D3D10 render/readback is unsupported, and make
macOS D3D10 rendering use CrossOver-equivalent fallback behavior: DXVK first,
then base WineD3D/Vulkan.

Small milestones:

- [x] G1-S1: Investigate CrossOver.app, CrossOver FOSS sources, GPTK 3.0, and
  GPTK 4.0 beta 1 D3D10 handling.
- [x] G1-S2: Correct parent GPTK component/import contracts so active
  `components/gptk-d3dmetal` does not require or report `d3d10.*`.
- [x] G1-S3: Add a runtime D3D10 bridge probe that calls `D3D10CreateDevice`,
  reaches GPTK's `DXGID3D10CreateDevice` bridge, and fails if Apple GPTK
  `d3d10.dll` is active.
- [x] G1-S4: Wire D3D10 GPTK smoke into runtime CI artifact and release
  promotion workflows.
- [x] G1-S5: Commit, push, open a draft PR, and stop before GPTK4 import work.
- [x] G1-S6: Add actual D3D10 render/readback smoke for the supported DXVK
  runtime route.
- [x] G1-S7: Align parent graphics backend hints so D3D10 selects DXVK and
  D3D11 keeps DXMT first.
- [x] G1-S8: Commit, push, open runtime PR #2, and update the parent PR.
- [x] G1-S9: Prove native GPTK/D3DMetal D3D10 render/readback or formally
  decide that macOS D3D10 rendering remains DXVK/WineD3D-backed.
- [x] G1-S10: Add a maintained GPTK D3D10 unsupported smoke that fails if
  GPTK/D3DMetal unexpectedly returns a render/readback success without a support
  contract review.
- [x] G1-S11: Add a maintained CrossOver-equivalent WineD3D/Vulkan D3D10
  render/readback smoke using the base Wine builtin route.
- [x] G1-S12: Align parent backend hints and launch behavior so D3D10 falls
  back from GPTK/D3DMetal to DXVK or WineD3D/Vulkan with an explicit reason.
- [x] G1-S13: Source-build CrossOver MoltenVK as an independent runtime
  component, wire it into CI/runtime assembly, and prove the WineD3D/Vulkan
  D3D10 smoke against that component.

#### PR Gate: G1-P1 Superseded GPTK3 D3D10 Payload Import Contract

status: superseded
branch: `task/gptk3-d3d10-parent-import`
pull request: https://github.com/serika12345/Konyak/pull/32

Outcome:

- PR #32 merged parent-side tests and importer behavior that treated Apple GPTK
  `d3d10.dll` and `d3d10.so` as active GPTK component payloads.
- Later CrossOver/GPTK investigation showed that direction is incorrect for
  Konyak's single CrossOver Wine runtime: D3D10 should stay on base Wine and
  reach GPTK through D3D11/DXGI.
- The current G1-P2 gate corrects that behavior with a normal follow-up diff.
  Reset and force push are prohibited; incompatible changes are removed through
  corrective commits.

#### PR Gate: G1-P2 D3D10 GPTK Bridge Smoke Contract

status: completed
branch: `task/gptk-d3d10-smoke`
pull request: https://github.com/serika12345/Konyak/pull/33
runtime submodule pull request:
https://github.com/serika12345/konyak-macos-runtime/pull/1

Completion criteria:

- Remove active GPTK `d3d10.dll` and `d3d10.so` from parent component
  definitions, importer validation/copy lists, runtime availability checks, and
  test fixtures.
- Keep GPTK/D3DMetal launch overrides to
  `dxgi,d3d11,d3d12,nvapi64,nvngx=n,b`.
- Add a D3D10 backend probe and a `gptk-d3d10-bridge` smoke target that uses
  base Wine `d3d10.dll`, `d3d10_1.dll`, and `d3d10core.dll`, plus GPTK
  D3D11/DXGI component paths. If device creation succeeds, treat that as a full
  pass; if a CI host returns the known GPTK D3D10 bridge `E_FAIL`, accept only
  that exact signature under `KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1`.
- Make GPTK smoke fail if active GPTK component `d3d10.dll` or `d3d10.so` is
  present.
- Add the D3D10 smoke to build, artifact smoke, and candidate promotion
  workflows without creating a monolithic rerun unit.
- Update this file, `docs/progress.md`, and `docs/todo.md` with verification
  and next action.

Not included:

- GPTK version-selection CLI.
- GPTK4 payload acceptance.
- Metal 4 runtime behavior or UI.

Verification:

- `nix develop -c zsh -lc 'zsh -n scripts/build-backend-probes.zsh scripts/smoke-backend-device.zsh scripts/smoke-gptk-d3dmetal-local.zsh'`
  passed in `runtime/konyak-macos-runtime`.
- `nix develop -c zsh -lc './scripts/build-backend-probes.zsh .dart_tool/backend-probes'`
  passed in `runtime/konyak-macos-runtime`.
- `nix develop -c zsh -lc './scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk-d3d10-bridge-smoke-check dist/konyak-macos-wine-runtime-stack.tar.zst'`
  passed: D3D10 reached `DXGID3D10CreateDevice` and returned the known
  `0x80004005` CI bridge signature, D3D11 device smoke passed, and D3D12 device
  smoke passed.
- `nix develop -c zsh -lc 'dart test test/runtime_platform_definition_type_fronts_test.dart test/cli_contract_runtime_install_test.dart'`
  passed in `packages/konyak_cli`.
- `nix develop -c zsh -lc 'just cli-test'` passed with 370 tests.
- `nix develop -c zsh -lc 'just verify-governance'` passed.
- `nix develop -c zsh -lc 'just verify-safety'` passed.
- `nix develop -c zsh -lc 'just format-check'` passed.
- `nix develop -c zsh -lc 'just lint'` passed.

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G2-P1.

#### PR Gate: G1-P3 D3D10 DXVK Render Smoke and Backend Hint Contract

status: completed
branch: `task/gptk-d3d10-smoke`
pull request: https://github.com/serika12345/Konyak/pull/33
parent merge commit: `bb8fefc`
runtime submodule branch: `task/d3d10-render-smoke`
runtime submodule pull request:
https://github.com/serika12345/konyak-macos-runtime/pull/2
runtime merge commit: `9c5bdf1`

Completion criteria:

- Add a runtime D3D10 render/readback probe that fails unless a D3D10 device can
  clear a render target, copy it to a staging texture, and verify the pixel
  data.
- Add a maintained `dxvk-d3d10-render` smoke target and run it in build,
  artifact-smoke, and candidate-promotion workflows without merging it into
  Wine build rerun units.
- Keep DXMT covered by D3D11 smoke only; do not claim DXMT D3D10 support until a
  separate dynamic proof passes.
- Split parent graphics backend hints so macOS D3D10 recommends DXVK and macOS
  D3D11 keeps DXMT first with DXVK fallback.
- Update progress records and runtime import-contract documentation.

Not included:

- DXMT D3D10 support.
- GPTK4 import support.
- End-to-end game rendering proof beyond maintained runtime probes.

Verification:

- `nix develop -c zsh -lc 'zsh -n scripts/build-backend-probes.zsh scripts/smoke-backend-device.zsh scripts/check-dxvk-component.zsh scripts/check-dxmt-component.zsh && ./scripts/build-backend-probes.zsh .dart_tool/backend-probes && work=/tmp/konyak-d3d10-render-smoke-check; rm -rf "$work"; mkdir -p "$work/runtime" "$work/probes"; nix shell nixpkgs#gnutar -c tar -xaf dist/konyak-macos-wine-runtime-stack.tar.zst -C "$work/runtime"; ./scripts/check-dxvk-component.zsh "$work/runtime"; ./scripts/check-dxmt-component.zsh "$work/runtime"; ./scripts/smoke-backend-device.zsh "$work/runtime" dxvk-d3d10-render "$work/probes"; ./scripts/smoke-backend-device.zsh "$work/runtime" dxvk-d3d11 "$work/probes"; ./scripts/smoke-backend-device.zsh "$work/runtime" dxmt-d3d11 "$work/probes"'`
  passed in `runtime/konyak-macos-runtime`.
- `nix develop -c zsh -lc 'git diff --check && nix flake check -L --show-trace'`
  passed in `runtime/konyak-macos-runtime`.
- `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_program_execution_test.dart --plain-name "suggest-graphics-backend"'`
  passed.
- `nix develop -c zsh -lc 'just cli-test'` passed with 372 tests.
- `nix develop -c zsh -lc 'just verify-governance'` passed.
- `nix develop -c zsh -lc 'just verify-safety'` passed.
- `nix develop -c zsh -lc 'just format-check'` initially formatted
  `packages/konyak_cli/lib/src/domain/program/program_graphics_backend_hints.dart`
  and exited 1; after keeping that formatter output, rerun `just format-check`
  passed.
- `nix develop -c zsh -lc 'just lint'` passed.

Review gate:

- Runtime PR #2 was merged into runtime `main` as `9c5bdf1`. Parent PR #33 was
  merged into parent `main` as `bb8fefc`. Stop before G1-P4 implementation and
  G2-P1 GPTK4 import work.

#### PR Gate: G1-P4 GPTK D3D10 Unsupported and WineD3D Fallback Contract

status: completed
branch: `task/gptk-d3d10-fallback-contract`
pull request: https://github.com/serika12345/Konyak/pull/34
parent merge commit: `ab048d8`
runtime submodule branch: `task/d3d10-fallback-smoke`
runtime submodule pull request:
https://github.com/serika12345/konyak-macos-runtime/pull/3
runtime merge commit: `eedc190`

Implementation status as of 2026-07-06 15:46 JST:

- Runtime submodule adds `gptk-d3d10-unsupported` and
  `wined3d-d3d10-render` smoke targets. The GPTK target requires `dxgi` /
  `d3d11` from the isolated GPTK/D3DMetal component, forbids DXVK/DXMT and
  winevulkan render fallback, and treats the known `0x80004005` D3D10 result as
  the expected outcome. Wine `+loaddll` may label the component files as native
  or builtin; the route proof is the resolved component path. The WineD3D target
  requires builtin `dxgi`, `d3d10`, `d3d10core`, `d3d11`, `wined3d`, and
  `winevulkan`, then verifies render/readback.
- Runtime CI now has separate WineD3D/Vulkan D3D10 smoke jobs after assembled
  artifact download in build, candidate promotion, and artifact-smoke
  workflows.
- Parent CLI now keeps macOS D3D10 backend hints on DXVK first and exposes
  `wineDefault` as the D3DMetal fallback. When a macOS run request has
  GPTK/D3DMetal selected and the target PE imports D3D10 without D3D12, Konyak
  clears D3DMetal runtime settings for that run, removes stale GPTK override
  DLLs, and emits:
  `KONYAK_GRAPHICS_BACKEND_REQUESTED=gptk-d3dmetal`,
  `KONYAK_GRAPHICS_BACKEND_SELECTED=wined3d-vulkan`, and
  `KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON=gptkD3d10Unsupported`.
- Parent fallback now also covers generated pinned launchers, keeps D3DMetal
  selected when a D3D12 string signal such as `D3D12CreateDevice` is detected,
  and removes stale GPTK DLL overrides before fallback execution.
- Runtime smoke now accepts the hosted-runner GPTK unsupported GPU signature
  only when `KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1`; local D3D10 unsupported
  smoke still requires the narrower D3D10 `0x80004005` path.
- Runtime no longer carries the rejected WineD3D MoltenVK feature-gate patch.
  Instead, runtime adds `nix/moltenvk-crossover.nix`, which builds MoltenVK
  from the pinned CrossOver FOSS source, checks for the expected D3D10
  feature-advertisement source lines, and packages a universal
  `lib/libMoltenVK.dylib`.
- Runtime PR #3 GitHub Actions run
  https://github.com/serika12345/konyak-macos-runtime/actions/runs/28771060023
  passed the MoltenVK build, stack assembly, metadata generation, WineD3D/Vulkan
  D3D10 fallback smoke, GPTK/D3DMetal smoke, and all other PR checks; publish
  was skipped because this is a PR run.

Completion criteria:

- Add a maintained `gptk-d3d10-unsupported` smoke path that routes
  `dxgi`/`d3d11` from the isolated GPTK/D3DMetal component, proves Apple GPTK
  `d3d10.*` is not active, and expects the known unsupported result instead of
  render/readback success.
- Make `gptk-d3d10-unsupported` fail if `KONYAK_D3D10_RENDER_PROBE_OK` appears,
  or if loaded-DLL tracing shows the probe escaped to DXVK, DXMT, or winevulkan
  render fallback.
- Add a maintained `wined3d-d3d10-render` or equivalent smoke target that uses
  base Wine builtin `d3d10`, `d3d10core`, `d3d11`, `dxgi`, `wined3d`, and
  `winevulkan` without DXVK, DXMT, or GPTK override paths, and verifies D3D10
  render/readback.
- Update runtime CI so the WineD3D/Vulkan fallback smoke is rerunnable without
  rebuilding the CrossOver Wine derivation after a successful runtime artifact
  build.
- Add a separate `build-moltenvk-component` CI job that builds
  `konyak-macos-moltenvk` from CrossOver FOSS source, uploads
  `konyak-macos-moltenvk.tar.zst`, and lets downstream assembly/smoke rerun
  without rebuilding Wine.
- Remove generic Khronos MoltenVK binary download from
  `package-binary-components.zsh`; the runtime stack must consume the
  runtime-owner-produced CrossOver MoltenVK component.
- Update parent backend hint and launch contracts so macOS D3D10 prefers DXVK
  and can explicitly fall back to WineD3D/Vulkan when GPTK/D3DMetal is selected
  or requested for a D3D10 program.
- Machine-readable diagnostics must distinguish `requested=gptk-d3dmetal`,
  `selected=dxvk` or `selected=wined3d-vulkan`, and
  `reason=gptkD3d10Unsupported` when fallback is applied.
- Update `docs/progress.md`, `docs/todo.md`, this workstream plan, and runtime
  import-contract documentation.

Investigation evidence:

- Native Apple GPTK 3.0, Apple GPTK 4.0 beta 1, and CrossOver.app
  `apple_gptk` payload tests against the assembled Konyak runtime did not
  produce `ID3D10Device` through native GPTK/D3DMetal.
- CrossOver.app can render/readback D3D10, but tracing shows it uses builtin
  WineD3D/Vulkan rather than native GPTK/D3DMetal.
- CrossOver's D3D10 WineD3D/Vulkan route depends on its MoltenVK behavior, not
  on an extra WineD3D patch found in the FOSS Wine source. The compatible
  Konyak path is therefore a complete CrossOver MoltenVK source build.

Not included:

- GPTK4 import support.
- Claiming native GPTK/D3DMetal D3D10 render support.
- UI for manually selecting the fallback route.

Review gate:

- Runtime PR #3 was merged into runtime `main` as `eedc190`. Parent PR #34 was
  merged into parent `main` as `ab048d8`. Continue to G2-P1 for
  version-specified GPTK import before GPTK4 payload support.

### G2: Version-Specified GPTK Import Contract

Goal: make GPTK import version-aware before accepting GPTK4, while preserving
the existing unversioned command as backward-compatible `auto` behavior.

Small milestones:

- [x] G2-S1: Extend request parsing with `--gptk-version <auto|3|4>`.
- [x] G2-S2: Add an explicit GPTK import version value object or sealed model.
- [x] G2-S3: Detect payload version from validated source metadata and payload
  shape.
- [x] G2-S4: Return clear JSON diagnostics when requested and detected versions
  do not match.
- [x] G2-S5: Document the flat command and future hierarchical alias behavior.

#### PR Gate: G2-P1 GPTK Version Parser and Request Model

status: completed
branch: `task/gptk-version-import-contract`
pull request: https://github.com/serika12345/Konyak/pull/35
parent merge commit: `0afa99f`

Implementation status as of 2026-07-06 16:43 JST:

- `install-gptk-wine --from <path> --json` still parses as a GPTK import
  request with `requestedVersion=auto`.
- `install-gptk-wine --from <path> --gptk-version <auto|3|4> --json` now
  preserves the requested version in `GptkWineInstallRequest`.
- Invalid `--gptk-version` values do not parse as this command. Stable
  requested/detected mismatch JSON diagnostics remain planned for G2-P2.

Completion criteria:

- Add parser tests for omitted `--gptk-version`, `auto`, `3`, `4`, and invalid
  values.
- Extend `GptkWineInstallRequest` with the requested version without changing
  existing call sites that omit the option.
- Preserve `install-gptk-wine --from <path> --json` behavior as `auto`.
- Update CLI usage text and contract documentation.
- Update this file and `docs/progress.md` with verification and next action.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

Review gate:

- Parent PR #35 was merged into parent `main` as `0afa99f`. Continue to G2-P2.

#### PR Gate: G2-P2 GPTK Version Detection and Mismatch Diagnostics

status: completed
branch: `task/gptk-version-detection`
pull request: https://github.com/serika12345/Konyak/pull/36
parent merge commit: `4e56d49`

Implementation status as of 2026-07-06 17:15 JST:

- GPTK payload version detection reads `D3DMetal.framework` Info.plist
  `CFBundleShortVersionString`, falling back to `CFBundleVersion`.
- `3.x` framework versions are detected as GPTK3; `4.x` and `4.0b1` are
  detected as GPTK4.
- Explicit requested version mismatches return JSON error code
  `gptkWineVersionMismatch` with stable `requestedVersion` and
  `detectedVersion` fields.
- `auto` accepts the detected version and continues to the existing payload
  validation path.

Completion criteria:

- Detect GPTK3 from `D3DMetal.framework` version `3.x` and compatible payload
  shape.
- Detect GPTK4 from `D3DMetal.framework` version `4.x` and compatible payload
  shape.
- Add tests for requested GPTK3 receiving GPTK4, requested GPTK4 receiving
  GPTK3, and `auto` accepting the detected version.
- JSON errors use stable codes and messages suitable for Flutter consumption.
- Update this file and `docs/progress.md` with verification and next action.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G3-P1.

### G3: GPTK4 Payload Variant Support

Goal: accept Apple GPTK 4.0 beta 1 payloads as a distinct supported variant
without weakening GPTK3 validation.

Small milestones:

- [x] G3-S1: Add GPTK4 fixture coverage with `atidxx64.*` absent.
- [x] G3-S2: Split GPTK required payload validation by detected/requested
  variant.
- [x] G3-S3: Install GPTK4 payloads into the canonical
  `components/gptk-d3dmetal` layout without active `d3d10.*`.
- [x] G3-S4: Preserve `nvngx-on-metalfx` normalization to canonical installed
  `nvngx` names.
- [ ] G3-S5: Capture public CLI import proof with the Apple GPTK 4.0 beta 1
  DMG.

#### PR Gate: G3-P1 GPTK4 Parent Import Variant

status: paused
branch: `task/gptk4-parent-import-variant`
pull request: https://github.com/serika12345/Konyak/pull/37
implementation commit: `bb00c94`

Completion criteria:

- Add parent CLI/importer tests for GPTK4 payloads without `atidxx64.dll` and
  `atidxx64.so`.
- GPTK3 validation still requires `atidxx64.*`; GPTK4 validation does not.
- GPTK3 and GPTK4 both require active `d3d11.*`, `d3d12.*`, `dxgi.*`,
  `nvapi64.*`, and normalized `nvngx.*`; neither variant installs active
  `d3d10.*`.
- Public CLI import succeeds for a GPTK4 fixture and records detected version.
- Update this file and `docs/progress.md` with verification and next action.

Verification:

- `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart test/cli_contract_runtime_process_update_test.dart test/cli_app_runtime_json_test.dart test/runtime_platform_definition_type_fronts_test.dart'`
  passed.
- `nix develop -c zsh -lc 'dart format packages/konyak_cli/test/cli_contract_runtime_install_test.dart && cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart --plain-name "install-gptk-wine imports GPTK4 payloads without atidxx64"'`
  passed.
- `nix develop -c zsh -lc 'just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
  passed.

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G3-P2.

#### PR Gate: G3-P2 GPTK4 Runtime Submodule Import and Smoke Contract

status: planned
branch: `task/gptk4-runtime-import-smoke`

Completion criteria:

- Update runtime submodule import scripts to accept GPTK4 payloads without
  `atidxx64.*` and without active `d3d10.*`.
- Update backend smoke required paths to handle GPTK3 and GPTK4 variants
  explicitly.
- Update CI-only GPTK smoke preparation to keep GPTK3 smoke green while adding
  an explicit GPTK4-capable path when a GPTK4 source is supplied.
- Update archive exclusion checks to cover all GPTK3 and GPTK4 proprietary
  payload names.
- Update this file and `docs/progress.md` with verification and next action.

Verification:

- Runtime submodule import script smoke with GPTK3 source.
- Runtime submodule import script smoke with GPTK4 source when available.
- Relevant runtime backend smoke commands, allowing documented unsupported-host
  signatures only where existing policy allows them.
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G4-P1.

### G4: Public Execution Proof and Documentation

Goal: prove the completed GPTK3/GPTK4 import behavior through maintained public
Konyak execution paths and document the resulting support contract.

Small milestones:

- [ ] G4-S1: Capture public CLI GPTK3 import proof through
  `install-gptk-wine --from ... --json`.
- [ ] G4-S2: Capture public CLI GPTK4 import proof through
  `install-gptk-wine --gptk-version 4 --from ... --json`.
- [ ] G4-S3: Capture runtime availability proof through `list-runtimes --json`
  or the maintained runtime CLI smoke path.
- [ ] G4-S4: Capture GPTK D3D10/D3D11/D3D12 smoke proof through maintained
  runtime scripts.
- [ ] G4-S5: Update user-facing docs and runtime release docs with the
  supported GPTK3/GPTK4 matrix.

#### PR Gate: G4-P1 GPTK Import Public Proof and Docs

status: planned
branch: `task/gptk-import-public-proof-docs`

Completion criteria:

- Public CLI evidence proves GPTK3 import succeeds.
- Public CLI evidence proves GPTK4 import succeeds when `--gptk-version 4` is
  used.
- Maintained runtime smoke evidence proves GPTK D3D10/D3D11/D3D12 backend
  routing.
- Documentation distinguishes payload import compatibility from Metal 4 runtime
  enablement and host OS requirements.
- `docs/cli-distribution.md`, `docs/release.md`, and runtime submodule docs
  describe the supported payload matrix.
- `docs/progress.md` records completion, verification, and any remaining
  follow-up.

Verification:

- Public CLI GPTK3 import smoke with Apple GPTK 3.0 DMG.
- Public CLI GPTK4 import smoke with Apple GPTK 4.0 beta 1 DMG.
- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop for review before any UI or Metal 4 enablement work.

## Deferred Follow-Ups

- Flutter UI for choosing GPTK import version.
- Metal 4 backend environment and policy controls after GPTK4 import is
  accepted.
- End-to-end game rendering proof beyond maintained smoke/probe paths.
