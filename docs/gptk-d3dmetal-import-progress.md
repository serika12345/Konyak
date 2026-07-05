# GPTK/D3DMetal Import Progress

This file tracks the dedicated GPTK/D3DMetal import workstream. It is the
source of truth for milestone scope, PR gates, current status, and handoff
notes for GPTK 3 and GPTK 4 import compatibility.

Use `docs/todo.md` only as the top-level roadmap pointer. Use
`docs/progress.md` for the repository-wide current work snapshot.

## Current Snapshot

- Timestamp: 2026-07-06 01:10 JST
- State: `completed`
- Branch: `task/gptk-d3d10-smoke`
- Pull request: https://github.com/serika12345/Konyak/pull/33
- Active gate: `G1-P2 D3D10 GPTK Bridge Smoke Contract`
- Purpose: correct the earlier active GPTK `d3d10.*` payload direction, keep
  D3D10 on the base Wine builtin frontend, and add runtime smoke/CI proof that
  D3D10 reaches GPTK/D3DMetal through the selected D3D11/DXGI backend.
- Completed work: investigated Apple GPTK 3.0, Apple GPTK 4.0 beta 1,
  `/Users/masato/Documents/CrossOver.app`, and the CrossOver FOSS sources under
  `/Users/masato/Documents/sources`; confirmed CrossOver does not ship active
  GPTK `d3d10.dll` or `d3d10.so`; confirmed Wine D3D10 flows through
  `d3d10core` into D3D11/DXGI; confirmed Konyak launch overrides already kept
  GPTK D3DMetal to `dxgi,d3d11,d3d12,nvapi64,nvngx=n,b`; removed active GPTK
  `d3d10.*` from parent component/import contracts and fixtures; added the
  runtime D3D10 bridge probe and `gptk-d3d10-bridge` smoke target; wired the
  D3D10 bridge smoke into build, artifact-smoke, and candidate-promotion
  workflows; updated docs and progress records.
- Remaining work: review the parent PR and runtime submodule PR, then stop
  before GPTK4 import work.
- Next action: review https://github.com/serika12345/Konyak/pull/33 and
  https://github.com/serika12345/konyak-macos-runtime/pull/1; after merge,
  continue with G2-P1 version-specified GPTK import.
- Verification so far: passed. See the G1-P2 verification section below.
- Workstream separation: sub-agent tooling was not used because the available
  tool requires explicit user authorization before spawning agents. The
  investigation conclusion, implementation changes, and audit/verification
  results are kept separate in this file and the review package.

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
- GPTK/D3DMetal payloads remain user-imported. Do not redistribute Apple GPTK
  payloads from Konyak release artifacts.
- Parent repository code may consume and preserve runtime-owner-produced
  artifacts and user-provided GPTK payloads, but must not synthesize missing
  runtime components to compensate for an incomplete runtime artifact.
- Runtime submodule changes must be coordinated with parent repository consumer
  contracts when import scripts, smoke checks, archive exclusion checks, source
  manifests, component paths, or CI workflows change.

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
- GPTK 4.0 beta 1 import failure before version support:
  - Public command:
    `install-gptk-wine --from /Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg --json`
  - Exit code: `75`
  - JSON error code: `gptkWineInstallFailed`
  - Message: `GPTK/D3DMetal payload is missing atidxx64.dll.`

## Large Milestones

### G1: D3D10 GPTK Routing and Smoke

Goal: prove D3D10 works with GPTK/D3DMetal without treating Apple GPTK
`d3d10.*` as an active component. D3D10 remains the base Wine frontend, while
GPTK supplies D3D11/DXGI/D3D12/NVIDIA shim payloads.

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

### G2: Version-Specified GPTK Import Contract

Goal: make GPTK import version-aware before accepting GPTK4, while preserving
the existing unversioned command as backward-compatible `auto` behavior.

Small milestones:

- [ ] G2-S1: Extend request parsing with `--gptk-version <auto|3|4>`.
- [ ] G2-S2: Add an explicit GPTK import version value object or sealed model.
- [ ] G2-S3: Detect payload version from validated source metadata and payload
  shape.
- [ ] G2-S4: Return clear JSON diagnostics when requested and detected versions
  do not match.
- [ ] G2-S5: Document the flat command and future hierarchical alias behavior.

#### PR Gate: G2-P1 GPTK Version Parser and Request Model

status: planned
branch: `task/gptk-version-import-contract`

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

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G2-P2.

#### PR Gate: G2-P2 GPTK Version Detection and Mismatch Diagnostics

status: planned
branch: `task/gptk-version-detection`

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

- [ ] G3-S1: Add GPTK4 fixture coverage with `atidxx64.*` absent.
- [ ] G3-S2: Split GPTK required payload validation by detected/requested
  variant.
- [ ] G3-S3: Install GPTK4 payloads into the canonical
  `components/gptk-d3dmetal` layout without active `d3d10.*`.
- [ ] G3-S4: Preserve `nvngx-on-metalfx` normalization to canonical installed
  `nvngx` names.
- [ ] G3-S5: Capture public CLI import proof with the Apple GPTK 4.0 beta 1
  DMG.

#### PR Gate: G3-P1 GPTK4 Parent Import Variant

status: planned
branch: `task/gptk4-parent-import-variant`

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

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

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
