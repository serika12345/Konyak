# Konyak

## Product

Konyak manages Wine/Proton bottles and launches Windows applications from a
Flutter UI backed by a Dart CLI.

Konyak targets arm64 macOS first and x86_64 Linux second.
Konyak owns its bottle metadata, managed runtime installation, and update flows
instead of relying on live external plist metadata. The Flutter app lives in
`apps/konyak`, and the CLI backend lives in `packages/konyak_cli`.

Konyak is distributed under the MIT License.

Technical details are kept in developer documentation:

- [AGENTS.md](AGENTS.md): repository engineering contract
- [docs/flutter-architecture-plan.md](docs/flutter-architecture-plan.md):
  architecture and system shape
- [docs/todo.md](docs/todo.md): remaining roadmap work
- [docs/progress.md](docs/progress.md): current handoff state
- [docs/release.md](docs/release.md): release builds, artifacts, and smoke
  checks
- [docs/cli-distribution.md](docs/cli-distribution.md): Flutter-to-CLI
  distribution contract
- [runtime/konyak-macos-runtime/README.md](runtime/konyak-macos-runtime/README.md):
  macOS runtime build and release contract

## Build

Run builds through the Nix flake.

macOS release build:

```sh
nix develop -c zsh -lc 'just macos-release'
```

Linux release build:

```sh
nix develop -c zsh -lc 'just linux-release'
```
