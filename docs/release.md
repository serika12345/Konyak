# Release

Konyak release builds run through Nix. The macOS path builds the Dart CLI as a
native executable, bundles it into `Konyak.app`, ad-hoc signs the bundle,
packages an unnotarized DMG artifact, and writes SHA-256 metadata for update
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
- `Konyak-<version>-macos-<arch>.dmg`
- `Konyak-<version>-macos-<arch>.dmg.sha256`
- `Konyak-<version>-macos-<arch>.release.json`
- `SHA256SUMS`
- `release-notes.md`

The `.app` bundle includes `Konyak-MIT.txt`, `THIRD_PARTY_NOTICES.md`, and
other bundled dependency notices under `Contents/Resources/Licenses`. macOS
builds also bundle the Zstandard `zstd` helper and `libzstd` so the packaged
CLI can extract managed runtime stack `.tar.zst` archives without depending on
developer shell tools or a user-installed `zstd`.

The local `Konyak.app` copy is replaced on every release build and is the app
used by the packaged runtime extraction smoke. The DMG artifact is packaged
from that same refreshed app copy with `create-dmg`. It opens as a conventional
drag-copy installer window with a background arrow, `Konyak.app`, and an
`Applications` drop link.

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
nix develop -c zsh -lc 'just smoke-macos-dmg-layout'
nix develop -c zsh -lc 'just smoke-macos-finder'
nix develop -c zsh -lc 'just smoke-macos-app-cli-bridge'
nix develop -c zsh -lc 'just smoke-macos-app-update-handoff'
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
`smoke-macos-app-update-handoff` invokes the release app's bundled CLI through
`install-app-update --json` with local `file://` release metadata, a
checksum-verified update DMG, a temporary `Konyak.app` target, and a disposable
running app PID. It waits for the handoff helper to mount the DMG, copy the
updated app bundle out of it, terminate that PID, replace the target bundle,
and remove staging/backup paths, proving the packaged macOS app replacement
path without touching `/Applications`.
`smoke-macos-dmg-layout` mounts the generated DMG read-only and verifies the
`create-dmg` layout payload: the background image, Finder `.DS_Store` icon-view
metadata, `Konyak.app`, and the `Applications -> /Applications` drop link.

## Local Linux Build

```sh
nix run .#linux-release
```

The same build remains available from the dev shell:

```sh
nix develop -c zsh -lc 'just linux-release'
```

For the full local Linux packaging check, including release metadata smoke,
AppRun environment smoke, AppImage update handoff smoke, bundled runtime
source-manifest signature verification, and remote runtime installation through
the public CLI contract, run:

```sh
nix develop -c zsh -lc 'just linux-release-check'
```

The same full check is available in VSCode as:

```text
Tasks: Run Task -> Konyak: Build Linux AppImage + Runtime Install Smoke
```

CI keeps this coverage split into rerunnable pieces: the release workflow
first runs `just verify`, then builds the Linux AppImage and runs the release
metadata, AppRun, AppImage update handoff, and Linux desktop integration smokes.
GitHub Release asset publishing waits for the release workflow's verify,
Linux, and macOS jobs to finish successfully. The Linux Runtime CLI Smoke
workflow separately verifies the remote runtime install path.

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
When automatic Konyak update checks are enabled, Linux AppImage builds prompt
the user on startup after an available app update is found, then invoke that
verified install path only after the user confirms installation.
The installer verifies that the current AppImage exists and that its directory
is writable before the app is terminated; AppImages installed in read-only or
Nix-managed locations should be updated by the package manager instead.
`smoke-linux-appimage-update-handoff` invokes the release AppDir's bundled CLI
through `install-app-update --json` with local `file://` release metadata, a
checksum-verified AppImage, a temporary current AppImage target, and a
disposable running app PID. It waits for the handoff helper to terminate that
PID, replace the target AppImage, relaunch the updated AppImage, and remove
staging/backup paths.

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
helpers are available and verified macOS app updates can mount a downloaded
DMG, copy out the updated `.app` bundle, terminate the running app, replace the
current `.app` bundle, and relaunch it. When automatic Konyak update checks are
enabled, packaged macOS builds prompt the user on startup after an available app
update is found, then invoke that verified install path only after the user
confirms installation.

## GPTK/D3DMetal Import Proof

Konyak releases do not bundle or redistribute Apple GPTK/D3DMetal payloads.
Release notes and support documentation must describe GPTK3/GPTK4 as
user-imported payload compatibility, not as a bundled runtime component or as
blanket Metal 4 enablement.

Before claiming GPTK3/GPTK4 import support for a release, run the maintained
public CLI smoke on macOS:

```sh
KONYAK_GPTK3_SOURCE_PATH=<user-provided-gptk3-dmg>
KONYAK_GPTK4_SOURCE_PATH=<user-provided-gptk4-dmg>
nix develop -c zsh -lc 'just smoke-macos-gptk-import-cli'
```

The smoke installs a fresh Konyak macOS runtime for each payload through
`install-macos-wine --reinstall --source-manifest ... --json`, then imports:

- Apple GPTK 3.x through `install-gptk-wine --from <gptk3-dmg> --json`.
- Apple GPTK 4.x through
  `install-gptk-wine --from <gptk4-dmg> --gptk-version 4 --json`.

It then verifies `list-runtimes --json` reports the optional
`gptk-d3dmetal` component and backend as available, checks that GPTK4 did not
install legacy `atidxx64.*` payloads, and runs the maintained
`gptk-d3d10-unsupported`, `gptk-d3d11-device`, and `gptk-d3d12-device` runtime
smoke targets against both imported runtimes.

## GitHub Release Workflow

`.github/workflows/publish.yml` runs on `v*` tags and manual dispatch. The
workflow uploads macOS and Linux release artifacts for every run. Tag builds also publish
the artifacts to the matching GitHub release.

The release workflow intentionally has no Apple Developer ID, App Store Connect,
or notarization secrets. Published macOS artifacts are ad-hoc signed and
unnotarized. Users should expect Gatekeeper quarantine handling for downloaded
builds.

## Release Preparation Automation

Release preparation is automated by `scripts/prepare_release.py` and the
`Prepare Konyak Release` GitHub Actions workflow. The app release version remains
the `version:` value in `apps/konyak/pubspec.yaml`; the CLI package version is
not used as the app release number.

To prepare a release locally from a clean branch:

```sh
nix develop -c zsh -lc 'just prepare-release --bump patch --commit --tag'
```

Use `--version <major.minor.patch>` instead of `--bump patch` when the exact
version should be chosen explicitly. The script increments the Flutter build
number by default, or accepts `--build-number <number>`. To include release
notes in the release commit and GitHub Release body, write a Markdown draft and
pass it with `--release-notes <path>`. The draft is copied to
`docs/releases/v<version>.md` before the release gates run.

For a full local release-candidate gate on the current host platform, use:

```sh
nix develop -c zsh -lc 'just prepare-release --version 1.2.3 --release-notes .dart_tool/konyak/release-notes.md --gate "just release-candidate-gates" --commit --tag --push --dispatch-publish'
```

`just release-candidate-gates` runs `just verify` first. On macOS it then builds
the macOS DMG and runs the packaged runtime extraction, DMG layout, PuTTY-backed
Finder, packaged app CLI bridge, and app update handoff smokes. On Linux it runs
`just linux-release-check`, which builds the AppImage and runs the Linux release
checks plus runtime install smoke. If any gate or build fails, the script restores
`apps/konyak/pubspec.yaml`, removes the copied `docs/releases/v<version>.md`, and
does not commit, tag, push, or dispatch publishing.

The release-preparation contract is:

- fail unless the git worktree is clean before the version update
- update `apps/konyak/pubspec.yaml`
- copy `--release-notes` into `docs/releases/v<version>.md` when provided
- run release gates, defaulting to `just verify`, before any commit or tag
- restore the pubspec, remove copied release notes, and leave no tag when a
  release gate fails
- commit the version update as `Release v<version>` when `--commit` is used
- create an annotated `v<version>` tag when `--tag` is used
- push the release commit and tag when `--push` is used
- dispatch `.github/workflows/publish.yml` on the created tag when
  `--dispatch-publish` is used

The GitHub `Prepare Konyak Release` workflow performs that same preparation from
a selected branch. It accepts either an explicit version or a major/minor/patch
bump, an optional build number, and an optional Markdown release-notes body. It
runs the default release gate inside the Nix dev shell, pushes the resulting
release commit and annotated tag, and then dispatches `publish.yml` on the tag
ref. That explicit dispatch is intentional: tags created by the workflow token
should not be the only mechanism that starts artifact publication. The existing
`Konyak Release` workflow remains the source of truth for building, smoking,
uploading, and publishing the macOS and Linux release artifacts. The publish job
reads `docs/releases/v<version>.md` from the tag ref when present, then appends
generated SHA-256 checksums to the GitHub Release body. If a publish workflow
build or smoke fails, no GitHub Release is created or updated.

## Update Metadata

`check-app-update --json` reads GitHub release metadata. The release body should
include a SHA-256 line that contains the artifact file name, matching the
generated `SHA256SUMS` format:

```text
<64 hex chars>  Konyak-<version>-macos-<arch>.dmg
```

`install-app-update --json` refuses to use a downloaded update artifact unless
the release metadata includes a valid SHA-256 checksum and the downloaded file
matches it. On macOS packaged builds it stages the verified DMG, mounts it
read-only, copies out the updated `.app` bundle, terminates the running app,
replaces the current bundle with rollback backup handling, and relaunches the
updated app. Existing zip-style macOS update artifacts remain supported by the
handoff extractor for compatibility. If the current bundle lives in a location
such as `/Applications` where the user cannot write directly, the handoff asks
macOS for administrator authorization before performing the replacement. On
Linux AppImage builds it verifies the current AppImage target before
termination, stages the verified AppImage, replaces the running artifact in
place after termination, and relaunches the updated app.

## Runtime Stack Releases

The detailed macOS runtime compatibility direction is tracked in
`runtime/konyak-macos-runtime/docs/crossover-runtime-compatibility.md`.

macOS runtime stack manifests remain checksum-validated JSON consumed by
`install-macos-wine --source-manifest`. The public release artifact is a single
assembled runtime stack archive for the default macOS runtime. Component
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
The published manifest for the default runtime stack points at the single
assembled archive containing Wine, DXVK-macOS, DXMT, MoltenVK, GStreamer,
FreeType, wine-mono, wine-gecko, and winetricks. Release verification checks
the component artifacts before assembly, then checks the assembled archive for
Wine32-on-64 payloads, Wine addon MSI payloads, the 32-bit `cmd.exe` smoke,
DXMT layout, DXVK layout including `d3d10.dll` and `d3d10_1.dll` for both i386
and x86_64 Windows payloads, GStreamer plugin/scanner presence, and no
unpackaged Nix store dylib references.

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
