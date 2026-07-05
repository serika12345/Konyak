# GPTK/D3DMetal Import Progress

This file tracks the dedicated GPTK/D3DMetal import workstream. It is the
source of truth for milestone scope, PR gates, current status, and handoff
notes for GPTK 3 and GPTK 4 import compatibility.

Use `docs/todo.md` only as the top-level roadmap pointer. Use
`docs/progress.md` for the repository-wide current work snapshot.

## Current Snapshot

- Timestamp: 2026-07-05 23:40 JST
- State: `planned`
- Branch: none yet
- Active gate: `G1-P1 GPTK3 D3D10 Parent Import Contract`
- Purpose: restore complete GPTK 3 payload import by carrying `d3d10.dll` and
  `d3d10.so`, then add explicit GPTK version selection before accepting GPTK 4
  beta payloads.
- Completed work: investigated Apple GPTK 3.0 and Apple GPTK 4.0 beta 1 DMGs;
  confirmed both include `d3d10.dll` and `d3d10.so`; confirmed GPTK 4.0 beta 1
  removes `atidxx64.dll` and `atidxx64.so`; confirmed current Konyak public CLI
  rejects GPTK 4.0 beta 1 at `install-gptk-wine --from ... --json` with
  `GPTK/D3DMetal payload is missing atidxx64.dll.`; incorporated the reporting
  format rule from PR #31 so GPTK milestone handoffs include change intent and
  what the change enables.
- Remaining work: implement and verify the PR gates below in order.
- Next action: create or continue `task/gptk3-d3d10-parent-import`, add failing
  GPTK3 `d3d10.*` command-level tests, implement the parent CLI/importer change,
  run the required verification, then stop at the G1-P1 review gate.
- Verification so far: planning documentation verification passed through the
  Nix dev shell with `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`; no implementation verification yet.

## Status Key

- `planned`: gate is defined but not started.
- `in_progress`: gate is actively being implemented.
- `paused`: work has stopped with a known resume point.
- `blocked`: work cannot continue without external input or state.
- `completed`: implementation, documentation, and required verification passed.
- `superseded`: scope was replaced by a later gate or design.

## Operating Rules

- Keep GPTK 3 support green before changing GPTK 4 behavior.
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
- For substantial implementation, keep investigation, implementation, and audit
  workstreams separate. If sub-agent tooling is unavailable or not approved,
  record the limitation and preserve the separation through written handoff
  notes in this file.

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
- GPTK 3.0 payload observations:
  - `D3DMetal.framework` version: `3.0`
  - `libd3dshared.dylib` present
  - Windows payloads include `atidxx64.dll`, `d3d10.dll`, `d3d11.dll`,
    `d3d12.dll`, `dxgi.dll`, `nvapi64.dll`, and `nvngx-on-metalfx.dll`
  - Unix payloads include matching `.so` symlinks to
    `../../external/libd3dshared.dylib`
- GPTK 4.0 beta 1 payload observations:
  - `D3DMetal.framework` version: `4.0b1`
  - `libd3dshared.dylib` present
  - Windows payloads include `d3d10.dll`, `d3d11.dll`, `d3d12.dll`,
    `dxgi.dll`, `nvapi64.dll`, and `nvngx-on-metalfx.dll`
  - Unix payloads include matching `.so` symlinks for those files
  - `atidxx64.dll` and `atidxx64.so` are absent
  - README documents `D3DM_MTL4` and `D3DM_MAX_FPS`
- Current Konyak failure:
  - Public command:
    `install-gptk-wine --from /Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg --json`
  - Exit code: `75`
  - JSON error code: `gptkWineInstallFailed`
  - Message: `GPTK/D3DMetal payload is missing atidxx64.dll.`

## Large Milestones

### G1: GPTK3 D3D10 Payload Completion

Goal: make Konyak's GPTK 3 import contract complete by preserving and
validating the D3D10 bridge payload that already exists in Apple GPTK 3.0.

Small milestones:

- [ ] G1-S1: Add failing parent CLI/importer tests proving GPTK3 `d3d10.dll`
  and `d3d10.so` are copied into `components/gptk-d3dmetal`.
- [ ] G1-S2: Add parent runtime component availability coverage for the
  installed GPTK3 D3D10 payload.
- [ ] G1-S3: Update runtime submodule import and smoke checks to carry and
  validate GPTK3 `d3d10.*`.
- [ ] G1-S4: Update archive exclusion checks and CI workflow copies of those
  checks so proprietary GPTK D3D10 files cannot enter runtime artifacts.
- [ ] G1-S5: Capture public CLI import proof with the Apple GPTK 3.0 DMG.

#### PR Gate: G1-P1 GPTK3 D3D10 Parent Import Contract

status: planned
branch: `task/gptk3-d3d10-parent-import`

Completion criteria:

- Add command-level tests for `install-gptk-wine --from <gptk3-source> --json`
  proving `d3d10.dll` and `d3d10.so` are installed under
  `components/gptk-d3dmetal/lib/wine/x86_64-*`.
- Update parent importer validation and copy behavior to require and preserve
  GPTK3 `d3d10.*`.
- Update parent runtime component definitions and test helpers so installed
  GPTK3 availability includes D3D10.
- Preserve existing JSON schema fields, exit codes, and flat command behavior.
- Update this file and `docs/progress.md` with verification and next action.

Not included:

- GPTK version-selection CLI.
- GPTK4 payload acceptance.
- Runtime submodule script or workflow edits.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

Review gate:

- Commit and push the branch, open a draft PR when GitHub access is available,
  then stop before G1-P2.

#### PR Gate: G1-P2 GPTK3 D3D10 Runtime Submodule Contract

status: planned
branch: `task/gptk3-d3d10-runtime-contract`

Completion criteria:

- Update `runtime/konyak-macos-runtime` import scripts to import GPTK3
  `d3d10.dll` and `d3d10.so`.
- Update runtime backend smoke required paths and diagnostics to include
  GPTK3 D3D10.
- Update runtime archive exclusion checks, including duplicated workflow
  expressions, to reject GPTK D3D10 payloads in distributable runtime archives.
- Keep runtime jobs rerunnable without forcing downstream smoke reruns to
  rebuild Wine.
- Update this file and `docs/progress.md` with verification and next action.

Not included:

- Parent CLI parser changes.
- GPTK4 payload acceptance.
- Metal 4 runtime behavior.

Verification:

- Runtime submodule script-level tests or smoke commands relevant to the edited
  scripts.
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

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

Not included:

- GPTK4 payload acceptance.
- Runtime submodule script changes.
- UI changes.

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

Not included:

- Relaxing GPTK4 `atidxx64.*` requirements.
- Metal 4 launch settings or UI controls.

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

- [ ] G3-S1: Add GPTK4 fixture coverage with `atidxx64.*` absent and
  `d3d10.*` present.
- [ ] G3-S2: Split GPTK required payload validation by detected/requested
  variant.
- [ ] G3-S3: Install GPTK4 payloads into the canonical
  `components/gptk-d3dmetal` layout.
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
- GPTK3 and GPTK4 both require `d3d10.*`, `d3d11.*`, `d3d12.*`, `dxgi.*`,
  `nvapi64.*`, and normalized `nvngx.*`.
- Public CLI import succeeds for a GPTK4 fixture and records detected version.
- Update this file and `docs/progress.md` with verification and next action.

Not included:

- Runtime submodule script changes.
- Metal 4 launch controls.
- UI surface for choosing GPTK version.

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
  `atidxx64.*`.
- Update backend smoke required paths to handle GPTK3 and GPTK4 variants
  explicitly.
- Update CI-only GPTK smoke preparation to keep GPTK3 smoke green while adding
  an explicit GPTK4-capable path when a GPTK4 source is supplied.
- Update archive exclusion checks to cover all GPTK3 and GPTK4 proprietary
  payload names.
- Update this file and `docs/progress.md` with verification and next action.

Not included:

- Parent CLI parser changes already covered by G2.
- Metal 4 enablement policy.

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
- [ ] G4-S4: Update user-facing docs and runtime release docs with the
  supported GPTK3/GPTK4 matrix.
- [ ] G4-S5: Record remaining Metal 4 runtime execution risks separately from
  payload import compatibility.

#### PR Gate: G4-P1 GPTK Import Public Proof and Docs

status: planned
branch: `task/gptk-import-public-proof-docs`

Completion criteria:

- Public CLI evidence proves GPTK3 import succeeds and includes D3D10 payloads.
- Public CLI evidence proves GPTK4 import succeeds when `--gptk-version 4` is
  used.
- Documentation distinguishes payload import compatibility from Metal 4 runtime
  enablement and host OS requirements.
- `docs/cli-distribution.md`, `docs/release.md`, and runtime submodule docs
  describe the supported payload matrix.
- `docs/progress.md` records completion, verification, and any remaining
  follow-up.

Not included:

- New Flutter UI controls.
- Metal 4 backend enable/disable UI.
- End-to-end game rendering proof beyond maintained smoke/probe paths.

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
- Hierarchical CLI alias such as `runtime import gptk --gptk-version <auto|3|4>`
  after the public shell CLI gate reaches runtime aliases.
- Metal 4 backend enablement policy, host OS detection, and launch environment
  controls for `D3DM_MTL4`.
- `D3DM_MAX_FPS` settings exposure.
- End-to-end DLSS/MetalFX and Metal 4 rendering proof with a redistributable or
  user-provided Windows program.
