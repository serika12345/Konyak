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
`.dart_tool/konyak/dev-runtime/linux-wine`. The dev shell prepares that runtime
from Nix-provided Wine, winetricks, and vkd3d-proton packages.

Local runtime stack fixtures must use the development-only
`KONYAK_DEV_LINUX_WINE_STACK_MANIFEST` environment variable. Keep release
variables such as `KONYAK_LINUX_WINE_STACK_MANIFEST` for published runtime stack
manifests.

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
