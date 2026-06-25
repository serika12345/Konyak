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

### P1: `validate-runtime` only proves loader startup

- Original evidence:
  - `packages/konyak_cli/lib/src/platform/macos/macos_runtime_validator.dart`
    checks runtime root, executable, a loader library directory, and
    `wineloader --version`.
- Why it is deceptive:
  - `wineloader --version` can pass while Wine32-on-64, Mono/Gecko, backend DLL
    routing, or prefix initialization are broken.
- Correct handling:
  - Include stack completeness in validation.
  - Add a separate application-owned prefix smoke that creates a fresh bottle
    without addon probing suppression.
  - Keep low-level loader checks, but label them as loader checks only.

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
    launches probes from the selected runtime backend directory instead of
    copying backend DLLs into the prefix.
  - It must not use `mscoree,mshtml=` or claim to prove Wine addon/prefix
    initialization behavior.

### P1: Raw Wine smoke scripts can be mistaken for app behavior proof

- Original evidence:
  - `scripts/run_macos_vulkan_wine_smoke.zsh` creates its own `WINEPREFIX` and
    invokes the runtime `wineloader` directly.
  - Runtime submodule smoke scripts also create their own prefixes.
- Why it is deceptive:
  - These scripts can be useful for low-level runtime diagnostics, but they do
    not prove the Flutter/CLI route, bottle metadata, or normal run planner.
- Correct handling:
  - Rename or document raw Wine smokes as low-level runtime diagnostics.
  - App behavior gates must call the CLI path or a maintained script that wraps
    that path.
