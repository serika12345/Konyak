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
`KONYAK_DEV_MACOS_WINE_STACK_MANIFEST` to a complete manifest URL or local file.
The parent repository does not generate macOS runtime component archives. Wine,
winetricks, Mono, Gecko, MoltenVK, FreeType, GStreamer, DXVK, DXMT, and vkd3d
must come from the `runtime/konyak-macos-runtime` produced stack manifest.

Linux development launches use `KONYAK_RUNTIME_PROFILE=development` and
`KONYAK_LINUX_WINE_HOME`, but the Nix dev shell does not provide Wine,
winetricks, or vkd3d-proton. Linux runtime contents must be installed through
`install-linux-wine` from a configured source manifest, matching the packaged
runtime acquisition path.

The flake keeps those concerns separate. `releaseBuildPackages` and the
platform build or packaging groups are for producing app artifacts. Verification
and workflow tools only enter the dev shell. `linuxHostRuntimePackages` are
Linux host helpers for local desktop/runtime testing, not Konyak-managed Wine
runtime contents. No parent dev-shell package group supplies managed runtime
payloads.

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

`AppRun` also accepts `--konyak-cli <command> ...` and dispatches that request
to the bundled CLI. Generated Linux pinned-program launchers use this stable
AppImage entry point instead of embedding the transient AppDir mount path, then
call `launch-pinned-program --manifest <manifest> --json` through the same CLI
contract as the Flutter app. This keeps packaged CLI resolution free of
build-machine paths and gives the CLI enough context to stage verified
in-place AppImage replacement on Linux.

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
verifies its SHA-256 checksum from release metadata before handoff. macOS DMG
builds mount the verified disk image, copy out the updated `.app`, terminate
the running app, replace the current bundle in place, and relaunch through a
detached helper script. Linux AppImage builds terminate the running AppImage,
replace it in place, and relaunch through the same detached-helper pattern.
macOS handoff uses standard administrator authorization when the current `.app`
bundle lives in a write-protected location such as `/Applications`. macOS
artifacts remain intentionally ad-hoc signed and unnotarized. Linux AppImage
startup prompts the user when automatic Konyak update checks are enabled and an
app update is available, then invokes the verified app-update install path only
after confirmation. The Linux handoff verifies that the current AppImage exists
and that its directory is writable before terminating the app; read-only and
Nix-managed locations should be updated outside the AppImage updater.

Deferred updater hardening requirements are:

- keep rollback or recovery behavior explicit for runtime and app updates

## Runtime Stack Manifests

macOS runtime stack construction starts at `install-macos-wine`. The public
command accepts a single `--source-manifest <path-or-url>` value or uses the
configured source manifest for the active runtime profile. Component archives
remain an internal source-manifest resolution detail: they are staged into one
Konyak-managed runtime directory and are expected to carry Konyak runtime
component layout. They may include `.konyak-runtime-stack.json` version
metadata.

The source manifest is versioned JSON:

- `schemaVersion`: `1`
- `runtimeId`: `konyak-macos-wine`
- `stackId`: `macos-konyak-runtime-stack`
- `components`: records with `id`, `version`, `archiveUrl`, and `sha256`

`install-macos-wine` verifies each component checksum before extraction. When
multiple component records point at the same `archiveUrl` and `sha256`, the
installer downloads and extracts that archive once while preserving the
per-component versions from the source manifest. This is the default macOS
release shape: the public manifest keeps component records for Wine,
DXVK-macOS, DXMT, vkd3d, MoltenVK, GStreamer, FreeType, wine-mono,
wine-gecko, and winetricks, but those records point at one assembled runtime
stack archive.
Runtime updates route through the same stack installer when release metadata
points at a manifest artifact. macOS GPTK/D3DMetal support uses the same
mechanism as the other macOS runtime components: a source manifest may include a
`gptk-d3dmetal` archive, and the installer normalizes it into
`components/gptk-d3dmetal/lib/external`,
`components/gptk-d3dmetal/lib/wine/x86_64-windows`, and
`components/gptk-d3dmetal/lib/wine/x86_64-unix`.

The default macOS runtime release is produced by the
`runtime/konyak-macos-runtime` submodule. Its source manifest includes the
CrossOver-derived Wine component, DXVK-macOS, DXMT, vkd3d, MoltenVK,
GStreamer, FreeType, wine-mono, wine-gecko, and winetricks component records
backed by the single public stack archive. Separate component archives remain
internal build and verification artifacts in the runtime workflow. The
`dxvk-macos` component is complete for D3D9, D3D10, D3D11, and DXGI on both
`i386-windows` and `x86_64-windows`; Actions verify that layout before
publishing the release. The `vkd3d` component is built in the runtime
submodule from the pinned CrossOver FOSS source and is overlaid into
`lib/wine/{i386,x86_64}-windows`; the parent repository must consume that
artifact instead of adding runtime vkd3d dependencies to the parent Nix flake.
The `gstreamer` component includes
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
bottle prefixes are kept outside the runtime root. CrossOver.app imports use
`Contents/SharedSupport/CrossOver/lib64/apple_gptk`, require the NVIDIA shim
files `nvapi64` and `nvngx`, and normalize older `nvngx-on-metalfx` source
names to the canonical `nvngx` runtime layout. User-imported GPTK/D3DMetal is
kept isolated under `components/gptk-d3dmetal`; reinstalling or updating the
managed macOS runtime preserves only that canonical component layout.

Development runtime preparation follows the same manifest-only boundary.
`scripts/prepare_macos_dev_runtime_stack.zsh` resolves a complete source
manifest produced by `runtime/konyak-macos-runtime` or an explicitly supplied
complete manifest. `scripts/prepare_linux_dev_runtime_source.zsh` resolves the
default complete Linux source manifest from `runtime/linux-wine-release.json`
or an explicitly supplied complete source manifest from
`KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST`, then validates and caches it.
Neither script creates component archives or overlays runtime files in the
parent repository.

Linux runtime construction now follows the same pattern through
`install-linux-wine`. A managed Linux stack may layer `vkd3d-proton` component
archives onto the base Wine runtime, or resolve a Linux runtime stack source
manifest that lists those archives and checksums.

Linux AppImage release builds now resolve the same default source manifest from
`runtime/linux-wine-release.json`, unless `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`
points at a specific valid Linux source manifest. `scripts/build_linux_release.zsh`
copies the resolved manifest into the release directory as
`konyak-linux-wine-runtime-stack-source.json`, bundles it under
`usr/share/konyak`, and exports `KONYAK_LINUX_WINE_STACK_MANIFEST` from
`AppRun` so the Settings runtime install action reaches the same source.

If the selected runtime release publishes
`konyak-linux-wine-runtime-stack-source.json.sig`, or
`KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64` is set, the build emits and bundles a
detached signature as `konyak-linux-wine-runtime-stack-source.json.sig` and
exports `KONYAK_LINUX_WINE_STACK_SIGNATURE_URL` from `AppRun`. If the selected
runtime release publishes `konyak-runtime-stack-public-key.pem`, or
`KONYAK_RUNTIME_STACK_PUBLIC_KEY` is set, the build emits and bundles
`konyak-runtime-stack-public-key.pem`, then exports
`KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH` and
`KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH` for runtime verifier use.

The release secret handoff for signed default Konyak runtime stack manifests is
documented in `docs/release.md`. The default Linux runtime manifest, detached
signature, public key, and current component archives are published by the
Linux runtime owner under `linux-wine-runtime-stack-0.1.0`. Remaining Linux
runtime-owner work is to add submodule-side component build/check workflows
before the next runtime version bump; the initial Wine archive still references
the upstream Kron4ek release rather than a Konyak-mirrored archive.

The maintained Linux runtime CLI smoke entry point is
`scripts/run_linux_runtime_cli_smoke.zsh`. It consumes a complete source
manifest, installs through `install-linux-wine --reinstall --source-manifest
... --progress-json --json`, then verifies `list-runtimes`, `validate-runtime`,
prefix creation, and the managed Winetricks route through public CLI commands.
It does not build or mutate Linux runtime component payloads in the parent
repository.

Do not replace this boundary with FFI or in-process linking unless the license
and platform implications are reviewed first.
