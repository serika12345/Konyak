# Release

Konyak release builds run through Nix. The macOS path builds the Dart CLI as a
native executable, bundles it into `Konyak.app`, ad-hoc signs the bundle,
packages an unnotarized zip artifact, and writes SHA-256 metadata for update
checks.

Linux release builds compile the same CLI, bundle it into the Flutter Linux
release tree, prepare an AppDir, and package that AppDir as an AppImage.
Wine/Proton runtime binaries are not bundled in either application artifact;
managed runtime components are downloaded after launch into the user's Konyak
runtime directory.

## Local macOS Build

```sh
nix run .#macos-release
```

The same build remains available from the dev shell:

```sh
nix develop -c zsh -lc 'just macos-release'
```

Outputs are written under `.dart_tool/konyak/release/macos`:

- `Konyak-<version>-macos-<arch>.zip`
- `Konyak-<version>-macos-<arch>.zip.sha256`
- `Konyak-<version>-macos-<arch>.release.json`
- `SHA256SUMS`
- `release-notes.md`

The `.app` bundle includes `Konyak-MIT.txt`, `THIRD_PARTY_NOTICES.md`, and
other bundled dependency notices under `Contents/Resources/Licenses`.

## Local Linux Build

```sh
nix run .#linux-release
```

The same build remains available from the dev shell:

```sh
nix develop -c zsh -lc 'just linux-release'
```

Outputs are written under `.dart_tool/konyak/release/linux`:

- `Konyak-<version>-linux-<arch>.AppImage`
- `Konyak-<version>-linux-<arch>.AppImage.sha256`
- `Konyak-<version>-linux-<arch>.release.json`
- `SHA256SUMS`
- `release-notes.md`
- `konyak-linux-wine-runtime-stack-source.json` when
  `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST` is provided
- `konyak-runtime-stack-public-key.pem` when
  `KONYAK_RUNTIME_STACK_PUBLIC_KEY` is provided alongside the manifest

The AppImage includes `Konyak-MIT.txt`, `THIRD_PARTY_NOTICES.md`, and other
bundled dependency notices under `usr/share/konyak/Licenses`.

The Flutter app is built with:

```text
--dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
```

At AppImage runtime, `AppRun` exports:

- `KONYAK_BUNDLE_RESOURCES=$APPDIR/usr/share/konyak`
- `KONYAK_APPIMAGE_PATH=$APPIMAGE`
- `KONYAK_APP_PID=<running Flutter process pid>`

This lets packaged builds invoke the bundled CLI directly from the AppImage and
lets Linux app updates hand off to a background replacement script that
terminates the running app, swaps in the verified AppImage, and relaunches it.

The Flutter app is built with:

```text
--dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
```

At runtime, the Flutter client resolves `__KONYAK_BUNDLE_RESOURCES__` to
`Konyak.app/Contents/Resources`, so packaged builds invoke the bundled CLI
directly instead of the development Dart script. The client also passes
`KONYAK_APP_EXECUTABLE` and `KONYAK_APP_PID` to the CLI so verified macOS app
updates can terminate the running app, replace the current `.app` bundle, and
relaunch it.

## GitHub Release Workflow

`.github/workflows/publish.yml` runs on `v*` tags and manual dispatch. The
workflow uploads macOS and Linux release artifacts for every run. Tag builds also publish
the artifacts to the matching GitHub release.

The release workflow intentionally has no Apple Developer ID, App Store Connect,
or notarization secrets. Published macOS artifacts are ad-hoc signed and
unnotarized. Users should expect Gatekeeper quarantine handling for downloaded
builds.

## Update Metadata

`check-app-update --json` reads GitHub release metadata. The release body should
include a SHA-256 line that contains the artifact file name, matching the
generated `SHA256SUMS` format:

```text
<64 hex chars>  Konyak-<version>-macos-<arch>.zip
```

`install-app-update --json` refuses to use a downloaded update artifact unless
the release metadata includes a valid SHA-256 checksum and the downloaded file
matches it. On macOS packaged builds it stages the verified zip, extracts the
updated `.app` bundle, terminates the running app, replaces the current bundle
with rollback backup handling, and relaunches the updated app. If the current
bundle lives in a location such as `/Applications` where the user cannot write
directly, the handoff asks macOS for administrator authorization before
performing the replacement. On Linux AppImage builds it stages the verified
AppImage, replaces the running artifact in place after termination, and
relaunches the updated app.

## Runtime Stack Releases

The detailed macOS runtime compatibility direction is tracked in
`runtime/konyak-macos-runtime/docs/crossover-runtime-compatibility.md`.

macOS runtime stack manifests remain checksum-validated JSON consumed by
`install-macos-wine --source-manifest`. The public release artifact should be a
single assembled runtime stack archive for the default macOS runtime. Component
archives may still be produced as internal CI artifacts so expensive Wine builds,
DXMT builds, binary component packaging, smoke verification, metadata, and
publishing remain separately rerunnable.

The macOS runtime stack itself is released from the
`runtime/konyak-macos-runtime` submodule. Its workflow keeps the expensive
CrossOver-derived Wine build, DXMT build, binary component packaging, metadata
generation, Wine32-on-64 smoke, and publish steps as separate rerunnable jobs.
The published manifest for the default runtime stack should point at the single
assembled archive containing Wine, DXVK-macOS, DXMT, MoltenVK, GStreamer,
FreeType, wine-mono, and winetricks. Release verification checks the component
artifacts before assembly, then checks the assembled archive for Wine32-on-64
payloads, the 32-bit `cmd.exe` smoke, DXMT layout, DXVK layout including
`d3d10.dll` and `d3d10_1.dll` for both i386 and x86_64 Windows payloads,
GStreamer plugin/scanner presence, and no unpackaged Nix store dylib references.

GPTK/D3DMetal remains user-imported rather than redistributed from release
assets. The runtime and CLI import contract accepts CrossOver.app's
`Contents/SharedSupport/CrossOver/lib64/apple_gptk` payload, requires
`nvapi64` and canonical `nvngx` NVIDIA shim files, and normalizes older
`nvngx-on-metalfx` source names into the installed runtime layout. The imported
payload is isolated under `components/gptk-d3dmetal`; macOS runtime reinstall
and update operations preserve that user-provided component instead of
overwriting base `lib/wine/*` files.

Reserved runtime-stack release inputs:

- `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`: path or generated artifact name for
  the default source manifest. Linux AppImage release builds validate this as a
  `konyak-linux-wine` / `linux-wine-runtime-stack` source manifest and publish
  it as `konyak-linux-wine-runtime-stack-source.json`.
- `KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64`: private signing key material for
  release automation. When this is set alongside
  `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`, Linux AppImage release builds emit a
  detached `konyak-linux-wine-runtime-stack-source.json.sig` signature and
  reference it from `.release.json`.
- `KONYAK_RUNTIME_STACK_PUBLIC_KEY`: public key text to publish with the
  manifest and embed into future verifier code. Linux AppImage release builds
  emit this value as `konyak-runtime-stack-public-key.pem` when a source
  manifest is also provided, bundle it into `usr/share/konyak`, and export
  `KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH` from `AppRun` for runtime verifier
  use.
