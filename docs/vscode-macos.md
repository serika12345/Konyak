# VSCode macOS Flutter Workflow

## Prerequisites

- Install the recommended VSCode extensions when prompted.
- Run `direnv allow` at the repository root.
- Open VSCode from an environment where direnv can load the Nix dev shell.
- Install and select full Xcode before building the macOS runner:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## Linux Note

On Linux, the Dart/Flutter extension should use the Flutter SDK from the Nix
dev shell directly. The macOS-only `FLUTTER_ROOT`, `DEVELOPER_DIR`, and
sanitized `PATH` overrides live in the macOS launch/task configuration so they
do not interfere with Linux daemon startup.

The Linux Nix dev shell and VSCode launch profile both set
`KONYAK_RUNTIME_PROFILE=development` and point `KONYAK_LINUX_WINE_HOME` at
`.dart_tool/konyak/dev-runtime/linux-wine`. The Linux VSCode launch profile runs
`scripts/prepare_linux_dev_runtime_source.zsh` before launch and passes
`KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST` to point at a different complete
source manifest produced by the Linux runtime packaging owner. That script does
not create Linux runtime components in the parent repository. It resolves the
default complete source manifest from `runtime/linux-wine-release.json`,
validates it, and caches it under
`.dart_tool/konyak/dev-runtime-source/linux-wine-stack`.
The first Settings install action still goes through Konyak's normal
`install-linux-wine` contract and installs into
`.dart_tool/konyak/dev-runtime/linux-wine`.
The dev shell also exports `KONYAK_LINUX_WINE_LIBRARY_PATH` so the managed
Linux Wine can find NixOS host libraries such as FreeType, Vulkan, EGL, and
GnuTLS without making those libraries part of the Konyak runtime payload.

Local runtime stack fixtures must use the development-only
`KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST` environment variable. Keep release
variables such as `KONYAK_LINUX_WINE_STACK_MANIFEST` for published runtime
stack manifests.

## Linux Release Tasks

Use these VSCode tasks for the common Linux packaging paths:

```text
Tasks: Run Task -> Konyak: Build Linux AppImage
Tasks: Run Task -> Konyak: Smoke Linux Runtime Install
Tasks: Run Task -> Konyak: Build Linux AppImage + Runtime Install Smoke
```

`Konyak: Build Linux AppImage` runs `just linux-release` and writes the
AppImage under `.dart_tool/konyak/release/linux`.

`Konyak: Build Linux AppImage + Runtime Install Smoke` runs
`just linux-release-check`. It builds the AppImage from the default Linux
runtime release, checks the generated release metadata, checks the AppRun
runtime environment exports, verifies the bundled runtime source manifest
signature, and then runs the public CLI runtime install smoke. This is the
shortest local check for "can build the Linux artifact and install the managed
runtime from the remote release assets".

The same full check can be run without VSCode:

```sh
nix develop -c zsh -lc 'just linux-release-check'
```

Set `KONYAK_LINUX_RELEASE_CHECK_SKIP_RUNTIME_INSTALL=true` when only the
AppImage build and bundled runtime manifest checks are needed.

The macOS VSCode launch profile uses the same development runtime profile. It
sets `KONYAK_RUNTIME_PROFILE=development`, points `KONYAK_MACOS_WINE_HOME` at
`.dart_tool/konyak/dev-runtime/macos-wine`, and points
`KONYAK_DEV_MACOS_WINE_STACK_MANIFEST` at the cached development source
manifest under `.dart_tool/konyak/dev-runtime-source/macos-wine-stack`.
`scripts/prepare_macos_dev_runtime_stack.zsh` resolves the selected Konyak
macOS runtime release from `runtime/macos-wine-release.json` and refreshes that
cache before launch. To switch the development build to another published
runtime release, set `KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG` before launching
VSCode or the Nix terminal task; use `latest` for the latest release. A complete
manifest URL can be forced with `KONYAK_DEV_MACOS_WINE_STACK_MANIFEST`.
These runtime values are passed both as process environment and as
`--dart-define` values so the Flutter app can forward them explicitly to the
CLI child process.

## Hot Reload Launch

Use the VSCode Run and Debug panel and select:

```text
Konyak Flutter (macOS)
```

This launches `apps/konyak/lib/main.dart` on the `macos` device in
Flutter debug mode. Hot reload is available from the Flutter/Dart debug toolbar,
and save-triggered hot reload is enabled in workspace settings.

Before launch, VSCode runs:

```text
Konyak: Prepare Flutter SDK macOS
```

The task creates `.dart_tool/konyak/flutter-sdk`, a local Flutter SDK view that
symlinks most of the Nix-provided SDK while copying the macOS engine artifacts
as writable files. The first run can take a little time because the copied
artifacts are hundreds of megabytes. The directory is ignored by git.

The same task also runs `scripts/prepare_macos_dev_runtime_stack.zsh`. It does
not install the runtime eagerly or build component archives in the parent
repository; it prepares a complete source manifest produced by
`runtime/konyak-macos-runtime` so the Konyak Settings runtime action can install
or repair `.dart_tool/konyak/dev-runtime/macos-wine` through the normal CLI
contract.

The launch configuration forces macOS Flutter builds to use the real Xcode
toolchain:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
PATH=/usr/bin:/bin:/usr/sbin:/sbin:.dart_tool/konyak/flutter-sdk/bin:$PATH
```

This is required because the Nix dev shell provides an Apple SDK and an `xcrun`
wrapper for package builds, but Flutter macOS desktop builds need Xcode's
`xcodebuild`. The local Flutter wrapper also starts Flutter with a sanitized
environment so Nix compiler variables do not leak into Xcode's `clang`.

## Agent Edit Watch

The Dart-Code debug launch hot reloads from VSCode save events. Edits made by
external tools such as Codex may update files on disk without producing the same
save event, so use this task when you want to watch coding-agent edits appear in
the running app:

```text
Tasks: Run Task -> Konyak: Flutter Run macOS (Agent Watch)
```

This starts `flutter run -d macos` inside `nix develop`, watches
`apps/konyak/lib/**/*.dart` and `apps/konyak/pubspec.yaml`,
and sends Flutter's terminal hot reload key automatically after file changes.
Native macOS project changes and dependency changes can still require a restart.

## Nix Terminal Fallback

If the Dart/Flutter extension does not inherit the direnv environment, run:

```text
Tasks: Run Task -> Konyak: Flutter Run macOS (Nix Terminal)
```

This starts `flutter run -d macos` inside `nix develop`. Use the terminal hot
reload keys from Flutter while that task is running.

## Troubleshooting

If the launch fails after changing `flake.nix` or updating the Nix Flutter
package, rebuild the local SDK view:

```sh
nix develop -c zsh -lc './scripts/prepare_flutter_macos_sdk.zsh --force --print-sdk-path'
```

If the launch fails with:

```text
error: tool 'xcodebuild' not found
```

run:

```text
Tasks: Run Task -> Konyak: Flutter Doctor macOS
```

The expected first line should resolve to:

```text
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
```

If it does not, install or repair full Xcode and rerun the prerequisite
commands above.
