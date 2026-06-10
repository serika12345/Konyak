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
`scripts/prepare_macos_dev_runtime_stack.zsh` resolves the selected Konyak
macOS runtime release from `runtime/macos-wine-release.json` and caches the
release source manifest consumed by `install-macos-wine --json`. Set
`KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG` to switch the development build to a
different published runtime release, or set
`KONYAK_DEV_MACOS_WINE_STACK_MANIFEST` to a complete manifest URL. Local
component archive generation is available only through
`KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE=local`. In that mode, the development
runtime source helper mirrors the released component layout instead of pulling
runtime libraries from the parent flake. The `dxvk-macos` component keeps the
pinned Gcenx DXVK-macOS payload and supplements only `d3d10.dll` and
`d3d10_1.dll` from upstream DXVK `v1.10.3` for both i386 and x86_64 Windows
payloads. If local source mode is used, the GStreamer component must be given
explicit plugin roots through `KONYAK_DEV_NIX_GSTREAMER_PLUGIN_PATHS` so it can
mirror the release component's `lib/gstreamer-1.0` plugin directory and
`libexec/gstreamer-1.0/gst-plugin-scanner`. The development winetricks
component is a checksum-verified upstream winetricks script plus its real
`list-all` verb catalog, not a stub. Override
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
`lib/external`, `lib/wine/x86_64-windows`, and `lib/wine/x86_64-unix`.

The default macOS runtime release is produced by the
`runtime/konyak-macos-runtime` submodule. Its source manifest currently
includes the CrossOver-derived Wine component, DXVK-macOS, DXMT, MoltenVK,
GStreamer, FreeType, wine-mono, and winetricks archives. The `dxvk-macos`
component is complete for D3D9, D3D10, D3D11, and DXGI on both
`i386-windows` and `x86_64-windows`; Actions verify that layout before
publishing the release. The `gstreamer` component includes
`libgstreamer-1.0.0.dylib`, plugin dylibs under `lib/gstreamer-1.0`, and
`libexec/gstreamer-1.0/gst-plugin-scanner`. macOS launch plans set
`GST_PLUGIN_SYSTEM_PATH`, `GST_PLUGIN_SCANNER`, and a bottle-local
`GST_REGISTRY` so Wine's media stack does not fall back to host GStreamer
plugins.

Konyak keeps the CrossOver-derived macOS Wine runtime as the default Wine
component. Users may import Apple GPTK DMGs, app bundles, or extracted redist
trees with
`install-gptk-wine --from <path> --json` to add Apple-provided D3DMetal files
without replacing the default Wine executable. Konyak validates the bundled
D3DMetal files and installs them as the optional `gptk-d3dmetal` component;
bottle prefixes are kept outside the runtime root.

The development stack script follows that model without assuming Konyak can
redistribute GPTK/D3DMetal in every environment. Set
`KONYAK_DEV_GPTK_D3DMETAL_PATH` to a local directory that contains
`D3DMetal.framework`, `libd3dshared.dylib`, the GPTK PE DLLs, and the matching
Unix libraries to add a `gptk-d3dmetal` component to the generated development
source manifest. The script accepts the external files at the directory root,
under `redist/lib/external`, under `lib/external`, under `Wine/lib/external`,
or under `Libraries/Wine/lib/external`, and resolves the matching
`wine/x86_64-windows` DLL directory and `wine/x86_64-unix` Unix library directory
from the same GPTK tree. If that variable is unset, the script omits
GPTK/D3DMetal from the generated stack.

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
documented in `docs/release.md`. Linux default full-stack manifest publication
and signing remain deferred until the Linux component archives exist.

Do not replace this boundary with FFI or in-process linking unless the license
and platform implications are reviewed first.
