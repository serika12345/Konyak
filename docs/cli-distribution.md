# CLI Distribution

Konyak keeps the Flutter UI and backend CLI as separate executables.

## Development Builds

Development builds run the CLI through Dart:

- executable: Flutter SDK `bin/dart`
- script: `packages/konyak_cli/bin/konyak.dart`

The Flutter app lives under `apps/konyak` and discovers the development
CLI through `KONYAK_DART_EXECUTABLE`, `KONYAK_CLI_SCRIPT`, or the default
repository-relative paths supplied by the VSCode launch configuration.

macOS development launches also use `KONYAK_RUNTIME_PROFILE=development`,
`KONYAK_MACOS_WINE_HOME`, and `KONYAK_DEV_MACOS_WINE_STACK_MANIFEST`.
`scripts/prepare_macos_dev_runtime_stack.zsh` prepares the development source
manifest and local component archives consumed by `install-macos-wine --json`.
The development winetricks component is a checksum-verified upstream winetricks
script plus its real `list-all` verb catalog, not a stub. Override
`KONYAK_DEV_WINETRICKS_PATH` to use a local executable or package root, or
override `KONYAK_DEV_WINETRICKS_SCRIPT_URL` and
`KONYAK_DEV_WINETRICKS_SCRIPT_SHA256` to change the pinned upstream source.

Linux development launches use `KONYAK_RUNTIME_PROFILE=development` and
`KONYAK_LINUX_WINE_HOME`, but the Nix dev shell does not provide Wine,
winetricks, or vkd3d-proton. Linux runtime contents must be installed through
`install-linux-wine` from a configured archive or source manifest, matching the
packaged runtime acquisition path.

The flake keeps those concerns separate. `releaseBuildPackages` and the
platform build or packaging groups are for producing app artifacts. Verification
and workflow tools only enter the dev shell. `linuxHostRuntimePackages` are
Linux host helpers for local desktop/runtime testing, not Konyak-managed Wine
runtime contents. `darwinDevelopmentRuntimeSourcePackages` are only source
inputs for local macOS development runtime components.

## Packaged Builds

Distribution builds bundle a compiled CLI executable and pass its path to the
Flutter app with `KONYAK_CLI_EXECUTABLE`. When this value is present, Flutter
invokes that executable directly and does not use the Dart script path.

macOS release builds are produced by `nix run .#macos-release` and use:

- bundled executable: `Konyak.app/Contents/Resources/konyak-cli`
- Dart define:
  `KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli`

The Flutter client resolves `__KONYAK_BUNDLE_RESOURCES__` from the running
`.app` bundle at runtime, so the packaged app does not depend on an absolute
build-machine path. CLI child processes also receive `KONYAK_APP_EXECUTABLE`
and `KONYAK_APP_PID`, allowing verified macOS update installation to replace
the running `.app` bundle and relaunch it.

Linux AppImage builds are produced by `nix run .#linux-release` and use:

- bundled executable: `AppDir/usr/share/konyak/konyak-cli`
- Dart define:
  `KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli`

The AppImage `AppRun` launcher exports:

- `KONYAK_BUNDLE_RESOURCES=$APPDIR/usr/share/konyak`
- `KONYAK_APPIMAGE_PATH=$APPIMAGE`
- `KONYAK_APP_PID=<current app pid>`

This keeps packaged CLI resolution free of build-machine paths and gives the
CLI enough context to stage verified in-place AppImage replacement on Linux.

The CLI boundary remains:

- process execution only
- argv-preserving command invocation
- versioned JSON stdout for application state
- stderr reserved for diagnostics

Update-related commands also stay behind this boundary:

- `check-app-update --json`
- `install-app-update --json`
- `check-runtime-update <id> --json`
- `install-runtime-update <id> --json`

Bottle state exposed through this boundary uses Konyak versioned JSON metadata.
The CLI does not read or write live external plist metadata as a supported bottle
format.

## Updates

Runtime update installation can update Konyak-managed runtime directories in
place. Konyak app update installation downloads the release artifact and
verifies its SHA-256 checksum from release metadata before handoff. macOS zip
builds and Linux AppImage builds then terminate the running app, replace the
current artifact in place, and relaunch through a detached helper script. macOS
handoff uses standard administrator authorization when the current `.app` bundle
lives in a write-protected location such as `/Applications`. macOS artifacts
remain intentionally ad-hoc signed and unnotarized.

Deferred updater hardening requirements are:

- keep rollback or recovery behavior explicit for runtime and app updates

## Runtime Stack Manifests

macOS runtime stack construction starts at `install-macos-wine`. The command can
accept a Wine archive plus one or more `--component-archive <path>` values, or a
single `--source-manifest <path-or-url>` value. Component archives are staged
into one Konyak-managed runtime directory and are expected to carry Konyak
runtime component layout. They may include `.konyak-runtime-stack.json` version
metadata.

The source manifest is versioned JSON:

- `schemaVersion`: `1`
- `runtimeId`: `konyak-macos-wine`
- `stackId`: `macos-konyak-runtime-stack`
- `components`: records with `id`, `version`, `archiveUrl`, and `sha256`

`install-macos-wine` verifies each component checksum before extraction. Runtime
updates route through the same stack installer when release metadata points at a
manifest artifact. macOS GPTK/D3DMetal support uses the same mechanism as the
other macOS runtime components: a source manifest may include a
`gptk-d3dmetal` archive, and the installer normalizes it into
`lib/external/D3DMetal.framework` and `lib/external/libd3dshared.dylib`. Konyak
does not expose a separate GPTK/D3DMetal installation flow; the component is
owned by the selected macOS runtime package.

The development stack script follows that model without assuming Konyak can
redistribute GPTK/D3DMetal in every environment. Set
`KONYAK_DEV_GPTK_D3DMETAL_PATH` to a local directory that contains
`D3DMetal.framework` and `libd3dshared.dylib` to add a `gptk-d3dmetal`
component to the generated development source manifest. The script accepts those
files at the directory root, under `lib/external`, under `Wine/lib/external`, or
under `Libraries/Wine/lib/external`. If that variable is unset, the script also
uses `.dart_tool/konyak/dev-runtime/macos-components/source-gptk-d3dmetal/Runtime`
when it already exists in the working tree.

Linux runtime construction now follows the same pattern through
`install-linux-wine`. A managed Linux stack may layer `vkd3d-proton` component
archives onto the base Wine runtime, or resolve a Linux runtime stack source
manifest that lists those archives and checksums.

Linux AppImage release builds can now publish that default source manifest and
the corresponding public key alongside the AppImage itself. When
`KONYAK_RUNTIME_STACK_SOURCE_MANIFEST` points at a valid Linux source manifest,
`scripts/build_linux_release.zsh` copies it into the release directory as
`konyak-linux-wine-runtime-stack-source.json`. If
`KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64` is also set, the build emits a
detached signature as `konyak-linux-wine-runtime-stack-source.json.sig`. If
`KONYAK_RUNTIME_STACK_PUBLIC_KEY` is also set, the build emits
`konyak-runtime-stack-public-key.pem` and references both files from the
generated `.release.json` metadata. AppImage builds also bundle that public key
under `usr/share/konyak` and export `KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH` from
`AppRun` so the CLI can verify signed manifest updates at runtime.

The release secret handoff for signed default Konyak runtime stack manifests is
documented in `docs/release.md`. The actual default full-stack manifest remains
deferred until the Konyak component archives exist, so the bootstrap Wine-only
fallback remains part of the CLI behavior.

Do not replace this boundary with FFI or in-process linking unless the license
and platform implications are reviewed first.
