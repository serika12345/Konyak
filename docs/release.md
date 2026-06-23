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

- `Konyak.app`
- `Konyak-<version>-macos-<arch>.zip`
- `Konyak-<version>-macos-<arch>.zip.sha256`
- `Konyak-<version>-macos-<arch>.release.json`
- `SHA256SUMS`
- `release-notes.md`

The `.app` bundle includes `Konyak-MIT.txt`, `THIRD_PARTY_NOTICES.md`, and
other bundled dependency notices under `Contents/Resources/Licenses`. macOS
builds also bundle the Zstandard `zstd` helper and `libzstd` so the packaged
CLI can extract managed runtime stack `.tar.zst` archives without depending on
developer shell tools or a user-installed `zstd`.

The local `Konyak.app` copy is replaced on every release build and is the app
used by the packaged runtime extraction smoke. The zip artifact is packaged
from that same refreshed app copy.

## Local macOS Packaged Debug App

Finder, LaunchServices, Quick Look, bundled helper tools, and packaged CLI
behavior must be checked against a finalized `.app` bundle rather than
`flutter run` or a loose build product. The development packaged app path is:

```sh
nix develop -c zsh -lc 'just macos-debug-app'
```

This writes a runnable debug app to:

- `.dart_tool/konyak/app/macos/debug/Konyak.app`

The debug and release paths both call `scripts/finalize_macos_app.zsh`, so
`Contents/Resources/konyak-cli`, `zstd`, `libzstd`, notices, licenses, and
ad-hoc signatures are prepared through the same finalization step.

The local Finder and runtime smokes are:

```sh
nix develop -c zsh -lc 'just smoke-macos-runtime-install'
nix develop -c zsh -lc 'just smoke-macos-finder'
nix develop -c zsh -lc 'just smoke-macos-app-cli-bridge'
nix develop -c zsh -lc 'just smoke-macos-finder-putty'
```

`smoke-macos-runtime-install` clears the inherited environment down to
`PATH=/usr/bin:/bin` before invoking the packaged CLI, which prevents the Nix
dev shell from hiding missing bundled helper tools. `smoke-macos-finder`
registers the packaged debug app with LaunchServices, verifies `.exe` content
type/default-handler resolution, opens a fixture through Finder's public
`open` path, and checks for a visible Konyak window. If
`KONYAK_MACOS_FINDER_SMOKE_EXE` or an explicit fixture path is provided, it
also runs `qlmanage` against that executable for local Quick Look thumbnail
coverage. `smoke-macos-finder-putty` downloads the PuTTY 0.84 standalone
64-bit Windows `putty.exe` fixture into `.dart_tool/konyak/fixtures/windows`,
verifies its pinned SHA-256 checksum, and runs the same Finder smoke with that
real PE executable. The release workflow runs that PuTTY-backed smoke against
the refreshed release `Konyak.app`, so CI and local verification use the same
finalized app layout instead of a manually placed `.app`.
`smoke-macos-app-cli-bridge` copies a finalized app bundle, replaces only the
bundled `Contents/Resources/konyak-cli` with a CLI spy, opens an `.exe` through
the same public `open` path, and verifies that Flutter invokes `run-program`
with `KONYAK_BUNDLE_RESOURCES` and a `PATH` beginning at
`Konyak.app/Contents/Resources`. That smoke keeps the Finder-to-Flutter-to-CLI
execution path covered without requiring a real Wine runtime in the release
workflow. The auto-run hook is only enabled when the smoke passes
`KONYAK_ENABLE_SMOKE_HOOKS=1`.

## Local Linux Build

```sh
nix run .#linux-release
```

The same build remains available from the dev shell:

```sh
nix develop -c zsh -lc 'just linux-release'
```

For the full local Linux packaging check, including release metadata smoke,
AppRun environment smoke, bundled runtime source-manifest signature
verification, and remote runtime installation through the public CLI contract,
run:

```sh
nix develop -c zsh -lc 'just linux-release-check'
```

The same full check is available in VSCode as:

```text
Tasks: Run Task -> Konyak: Build Linux AppImage + Runtime Install Smoke
```

CI keeps this coverage split into rerunnable pieces: the release workflow
builds the Linux AppImage and runs the release metadata/AppRun and Linux
desktop integration smokes, while the Linux Runtime CLI Smoke workflow verifies
the remote runtime install path.

Outputs are written under `.dart_tool/konyak/release/linux`:

- `Konyak-<version>-linux-<arch>.AppImage`
- `Konyak-<version>-linux-<arch>.AppImage.sha256`
- `Konyak-<version>-linux-<arch>.release.json`
- `SHA256SUMS`
- `release-notes.md`
- `konyak-linux-wine-runtime-stack-source.json`
- `konyak-linux-wine-runtime-stack-source.json.sig` when the selected runtime
  release publishes a signature or `KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64`
  is provided
- `konyak-runtime-stack-public-key.pem` when the selected runtime release
  publishes one or `KONYAK_RUNTIME_STACK_PUBLIC_KEY` is provided

The AppImage includes `Konyak-MIT.txt`, `THIRD_PARTY_NOTICES.md`, and other
bundled dependency notices under `usr/share/konyak/Licenses`.

The Flutter app is built with:

```text
--dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
```

At AppImage runtime, `AppRun` exports:

- `KONYAK_BUNDLE_RESOURCES=$APPDIR/usr/share/konyak`
- `KONYAK_APP_EXECUTABLE=$APPDIR/usr/konyak`
- `KONYAK_APPIMAGE_PATH=$APPIMAGE`
- `KONYAK_APP_ICON_PATH=$APPDIR/app.konyak.Konyak.png` when the AppDir icon is
  present
- `KONYAK_APP_PID=<running Flutter process pid>`

This lets packaged builds invoke the bundled CLI directly from the AppImage and
lets Linux app updates hand off to a background replacement script that
terminates the running app, swaps in the verified AppImage, and relaunches it.

On Linux startup, the Flutter app runs `install-linux-file-associations --json`
through the bundled CLI. That command rewrites the user-level desktop entry at
`$XDG_DATA_HOME/applications/app.konyak.Konyak.desktop` (or
`~/.local/share/applications/app.konyak.Konyak.desktop`), copies the Konyak icon
to the user hicolor icon theme, updates `.exe` and related Windows executable
MIME defaults in `$XDG_CONFIG_HOME/mimeapps.list` (or `~/.config/mimeapps.list`),
and refreshes desktop/icon caches when the host provides the standard tools. If
the user moves the AppImage, launching Konyak once from the new location
re-synchronizes the desktop entry `Exec=` path.

Pinned Windows programs are also synchronized through the public CLI path.
When a program is pinned, renamed, unpinned, or when `list-bottles --json`
refreshes the bottle catalog, Linux builds write visible launcher entries to
`$XDG_DATA_HOME/applications/app.konyak.Konyak.pinned.<id>.desktop` and keep
their manifests and wrapper scripts under
`$XDG_DATA_HOME/konyak/launchers/linux-pinned/<id>/`. The generated launcher
executes `launch-pinned-program --manifest <manifest> --json`, so bottle
lookup, runtime selection, logging, and program settings stay owned by Konyak
rather than by a desktop-entry-specific Wine command. AppImage launchers use
the stable `KONYAK_APPIMAGE_PATH` entry point with `--konyak-cli`, and `AppRun`
dispatches that mode to the bundled CLI, avoiding transient AppImage mount
paths in generated launchers.

The Flutter app is built with:

```text
--dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
```

At runtime, the Flutter client resolves `__KONYAK_BUNDLE_RESOURCES__` to
`Konyak.app/Contents/Resources`, so packaged builds invoke the bundled CLI
directly instead of the development Dart script. The client also passes
`KONYAK_BUNDLE_RESOURCES`, prepends that directory to `PATH`, and passes
`KONYAK_APP_EXECUTABLE` and `KONYAK_APP_PID` to the CLI so runtime extraction
helpers are available and verified macOS app updates can terminate the running
app, replace the current `.app` bundle, and relaunch it.

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
Final runtime Release assets are placed only after verification succeeds. CI
builds publish through the `Build runtime` workflow after the assembled runtime
stack passes layout checks and Wine32-on-64, GUI launch, DXVK, DXMT, and vkd3d
smoke tests. Locally produced runtime stacks may be staged only as draft
candidate releases in the runtime submodule; the `Promote runtime candidate`
workflow downloads those candidate assets, recalculates the stack archive
checksum, rewrites the source manifest to the final release URL, runs the same
smoke gates, and publishes the final Release only if every verification job
passes.
The published manifest for the default runtime stack should point at the single
assembled archive containing Wine, DXVK-macOS, DXMT, MoltenVK, GStreamer,
FreeType, wine-mono, wine-gecko, and winetricks. Release verification checks the
component artifacts before assembly, then checks the assembled archive for
Wine32-on-64 payloads, Wine addon MSI payloads, the 32-bit `cmd.exe` smoke, DXMT
layout, DXVK layout including `d3d10.dll` and `d3d10_1.dll` for both i386 and
x86_64 Windows payloads, GStreamer plugin/scanner presence, and no unpackaged
Nix store dylib references.

GPTK/D3DMetal remains user-imported rather than redistributed from release
assets. The runtime and CLI import contract accepts CrossOver.app's
`Contents/SharedSupport/CrossOver/lib64/apple_gptk` payload, requires
`nvapi64` and canonical `nvngx` NVIDIA shim files, and normalizes older
`nvngx-on-metalfx` source names into the installed runtime layout. The imported
payload is isolated under `components/gptk-d3dmetal`; macOS runtime reinstall
and update operations preserve that user-provided component instead of
overwriting base `lib/wine/*` files.

Reserved runtime-stack release inputs:

- `runtime/linux-wine-release.json`: default Linux runtime release locator for
  the complete source manifest produced by the Linux runtime packaging owner.
  Linux AppImage release builds resolve this locator when no explicit manifest
  override is supplied.
- `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`: path or URL override for the default
  source manifest. Linux AppImage release builds validate this as a
  `konyak-linux-wine` / `linux-wine-runtime-stack` source manifest, bundle it
  into the AppImage, and publish it as
  `konyak-linux-wine-runtime-stack-source.json`.
- `KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64`: private signing key material for
  release automation. When this is set, Linux AppImage release builds emit a
  detached `konyak-linux-wine-runtime-stack-source.json.sig` signature,
  bundle it into the AppImage, and reference it from `.release.json`.
- `KONYAK_RUNTIME_STACK_PUBLIC_KEY`: public key text to publish with the
  manifest and embed into future verifier code. Linux AppImage release builds
  emit this value as `konyak-runtime-stack-public-key.pem`, bundle it into
  `usr/share/konyak`, and export `KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH` from
  `AppRun` for runtime verifier use.
