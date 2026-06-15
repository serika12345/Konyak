# Runtime Integrity Debt Inventory

This inventory records implementation and verification paths that can make the
runtime look healthier than it is. The common failure mode is proving a shortcut
instead of proving the behavior Konyak actually needs.

## Scope

- Audit date: 2026-06-14
- Scope: macOS runtime, prefix initialization, release/update metadata,
  runtime validation, smoke scripts, and tests that currently define those
  contracts.
- Out of scope: optional UI-only degraded metadata such as missing executable
  icons, unless it hides runtime or installer failures.

## Repair Status

- Repair pass: 2026-06-14
- Status: completed for the root issues listed in the repair order.
- Verification:
  - CLI contract tests cover prefix initialization without `mscoree,mshtml=`,
    exact macOS Mono/Gecko payload completeness, install completion, validation
    stack checks, and macOS release source-manifest requirements.
  - `scripts/run_macos_runtime_cli_smoke.zsh` passed through the public CLI
    route against the rebuilt local runtime stack.
  - Runtime submodule checks passed for addon payload checks, Wine32-on-64,
    GUI launch, DXVK, DXMT, vkd3d, GStreamer, and backend device smokes.
- Follow-up repair pass: 2026-06-15
  - Removed parent-side winetricks script download/list-all fallback from the CLI
    execution path. Missing macOS `verbs.txt` or Linux managed `winetricks` now
    reports runtime incompleteness instead of mutating the runtime from the
    parent repository.
  - Removed parent-side local macOS component generation from
    `scripts/prepare_macos_dev_runtime_stack.zsh`; the helper now resolves only
    complete manifests produced by `runtime/konyak-macos-runtime`.
  - Removed parent-side Linux development component generation from
    `scripts/prepare_linux_dev_runtime_source.zsh`; Linux development now
    requires an explicit complete runtime source manifest instead of
    repackaging winetricks, Mono, DXVK, or vkd3d-proton in the parent
    repository.
  - Added runtime-submodule addon version verification that extracts Wine's
    embedded Mono/Gecko expectations from the CrossOver source archive and
    compares them with packaged addon component constants.
  - Renamed parent raw Wine/Vulkan just targets as low-level diagnostics and
    added governance checks so they cannot be mistaken for app behavior gates.
  - Split Linux runtime-settings environment generation from macOS-only
    D3DMetal/Metal/Rosetta variables.

## Inventory

### P0: Prefix initialization suppresses Wine addon probing

- Original evidence:
  - `packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart`
    appends `WINEDLLOVERRIDES=mscoree,mshtml=` for macOS prefix
    initialization.
  - `packages/konyak_cli/test/cli_contract_program_execution.part.dart` asserts
    that override.
  - `runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh`,
    `runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh`, and
    `runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh` do the same.
- Why it is deceptive:
  - It disables the Wine code path that decides whether Mono/Gecko are
    installed. A passing prefix smoke only proves that the prompt was avoided,
    not that the runtime satisfies Wine's addon contract.
- Correct handling:
  - Remove this override from application-owned prefix initialization and from
    any smoke that claims to validate prefix creation.
  - Package the Wine-expected Mono and Gecko payloads and let Wine find them via
    `WINEDATADIR`.
  - Add failing tests first that reject `mscoree,mshtml=` in prefix init plans.
  - Completed in the 2026-06-14 repair pass.

### P0: Wine Mono payload version is not tied to Wine's embedded expectation

- Original evidence:
  - CrossOver/Wine `appwiz.cpl` embeds `MONO_VERSION "10.4.1"` and
    `GECKO_VERSION "2.47.4"`.
  - `runtime/konyak-macos-runtime/scripts/package-binary-components.zsh` packages
    `wine-mono-11.1.0-x86.msi`.
  - No `wine-gecko` component is packaged or required by the parent runtime
    stack contract.
- Why it is deceptive:
  - `share/wine/mono` can exist while Wine still cannot find the exact local MSI
    it is compiled to request. Gecko is not represented at all, so `mshtml`
    probing can only be hidden, not satisfied.
- Correct handling:
  - Derive or assert Mono/Gecko versions from the built Wine source/runtime.
  - Package `wine-mono-${expected}-x86.msi` and the expected Gecko MSI payloads.
  - Add runtime-submodule checks that fail when packaged addon file names or
    hashes do not match Wine's embedded constants.
  - Completed by packaging `wine-mono-10.4.1-x86.msi` and
    `wine-gecko-2.47.4-{x86,x86_64}.msi` with checksum checks.

### P0: Runtime completeness accepts shallow addon markers

- Original evidence:
  - `packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart`
    only requires `share/wine/mono` for `wine-mono`.
  - Test fixtures use marker paths such as `share/wine/mono/wine-mono.marker`
    instead of the MSI name Wine needs.
- Why it is deceptive:
  - A directory or marker file can satisfy Konyak's stack completeness while
    Wine's actual addon installer cannot use it.
- Correct handling:
  - Replace directory-only checks with exact required files, expected versions,
    and checksums where the runtime owns the payload.
  - Add a required `wine-gecko` component.
  - Update fixtures to mirror real payload names, not marker placeholders.
  - Completed in parent runtime contracts and CLI fixtures.

### P0: Runtime install success does not require stack completeness

- Original evidence:
  - `packages/konyak_cli/lib/src/io/macos_wine_archive_installation.dart`
    reports completion once the runtime executable exists.
  - It returns `MacosWineInstallCompleted` even if required stack components are
    incomplete.
- Why it is deceptive:
  - A Wine-only archive can be reported as an installed runtime even when the
    advertised stack is unusable.
- Correct handling:
  - Full install and update install must fail unless the required stack is
    complete after normalization.
  - Component-only or repair operations may be partial only when explicitly
    named as such in the operation and result.
  - Completed for macOS archive/source-manifest installs.

### P1: `validate-runtime` only proves loader startup

- Original evidence:
  - `packages/konyak_cli/lib/src/platform/macos/macos_runtime_validator.dart`
    checks runtime root, executable, a loader library directory, and
    `wine64 --version`.
- Why it is deceptive:
  - `wine64 --version` can pass while Wine32-on-64, Mono/Gecko, backend DLL
    routing, or prefix initialization are broken.
- Correct handling:
  - Include stack completeness in validation.
  - Add a separate application-owned prefix smoke that creates a fresh bottle
    without addon probing suppression.
  - Keep low-level loader checks, but label them as loader checks only.
  - Completed with `runtime-stack` validation and CLI smoke coverage.

### P1: Release metadata falls back too silently

- Original evidence:
  - `packages/konyak_cli/lib/src/io/release_metadata_fetcher.dart` ignores
    failures while fetching the `.release.json` asset.
  - `packages/konyak_cli/lib/src/io/runtime_release_metadata_assets.dart`
    selects the first non-metadata archive by extension or finally the first
    non-metadata asset.
  - `packages/konyak_cli/test/cli_contract_runtime_process_update.part.dart`
    explicitly tests that missing source manifests are ignored.
- Why it is deceptive:
  - If release assets are deleted, renamed, or reordered, update checks can
    silently fall back from the stack source manifest path to a less precise
    archive path.
- Correct handling:
  - For macOS Konyak runtime releases, require the configured source manifest
    file name from `runtime/macos-wine-release.json`.
  - Treat an advertised but unavailable `.release.json` or source manifest as a
    failed update check.
  - Select release assets by expected file name, not by first matching
    extension.
  - Completed for advertised `.release.json` fetch failures and macOS runtime
    update checks without source manifests.

### P1: Backend smoke copies override DLLs into the prefix

- Original evidence:
  - `runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh` copies
    backend DLLs into `drive_c/windows/system32` and `syswow64` before running
    probes.
- Why it is deceptive:
  - If presented as generic launch parity, copying DLLs into the prefix can hide
    broken `WINEDLLPATH` or DLL override behavior.
- Correct handling:
  - Backend smoke must be documented as a component-local diagnostic that
    mirrors Konyak `set-runtime-settings` backend DLL placement.
  - It must not use `mscoree,mshtml=` or claim to prove Wine addon/prefix
    initialization behavior.
  - Completed by removing addon probing suppression and documenting the backend
    DLL placement role.

### P1: Raw Wine smoke scripts can be mistaken for app behavior proof

- Original evidence:
  - `scripts/run_macos_vulkan_wine_smoke.zsh` creates its own `WINEPREFIX` and
    invokes the runtime `wine64` directly.
  - Runtime submodule smoke scripts also create their own prefixes.
- Why it is deceptive:
  - These scripts can be useful for low-level runtime diagnostics, but they do
    not prove the Flutter/CLI route, bottle metadata, or normal run planner.
- Correct handling:
  - Rename or document raw Wine smokes as low-level runtime diagnostics.
  - App behavior gates must call the CLI path or a maintained script that wraps
    that path.
  - Completed by keeping `scripts/run_macos_runtime_cli_smoke.zsh` as the app
    behavior gate, renaming parent raw Wine just targets to `diagnose-*`, and
    making AGENTS plus governance checks enforce the execution-path SSOT.

### P1: Documentation currently records the wrong conclusion

- Original evidence:
  - `docs/progress.md` records Mono/MSHTML suppression as a stabilization step.
  - `docs/todo.md` still has Phase 3 runtime normalization open while older
    progress text says the phase was completed.
- Why it is deceptive:
  - The docs make a masked smoke result look like a completed compatibility
    milestone.
- Correct handling:
  - Supersede the masked-smoke notes with this inventory.
  - Track the actual repair as open TODO work until addon payloads, validation,
    and CLI-path smoke are fixed.
  - Completed by marking the repair TODO done and adding this repair status.

## Repair Order

1. Remove prefix-init `mscoree,mshtml=` from the CLI contract and update tests
   to reject it.
2. Package Wine-expected Mono and Gecko payloads in the runtime submodule and
   verify their file names and hashes against the built Wine expectation.
3. Strengthen parent runtime completeness and install success checks so full
   installs cannot complete with shallow marker payloads or incomplete stacks.
4. Replace release/update fallback behavior with exact source-manifest asset
   requirements for Konyak macOS runtime releases.
5. Split smoke labels: CLI-path smokes prove app behavior; raw Wine smokes prove
   only low-level runtime properties.
6. Document backend smokes as component diagnostics that mirror Konyak backend
   DLL placement and do not suppress addon probing.
