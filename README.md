# Konyak

Konyak manages Wine/Proton bottles and runs Windows applications from a Flutter
desktop UI backed by a tested Dart CLI.

Konyak owns its bottle metadata, runtime packaging, CI, and development
workflow. External plist metadata is not part of the supported data
model.

## Status

- arm64 macOS is the first complete runtime target.
- x86_64 Linux is the second complete runtime target.
- Flutter calls the backend through JSON CLI contracts.
- Wine/Proton runtimes are managed by Konyak and installed per platform.
- macOS uses a Konyak-managed Wine stack published as a single assembled
  archive, with separately verified component build units.

Remaining product work is tracked in `docs/todo.md`. The current active work,
handoff notes, and next continuation step are tracked in `docs/progress.md`.
The main open areas are end-to-end DLSS/MetalFX rendering proof, the remaining
Flutter UI file split, Linux ARM64 Windows execution research, Linux executable
thumbnail strategy for sandboxed file managers, E2E test target selection,
Linux runtime submodule build/check hardening before the next runtime bump, and
eventual removal of legacy archive/Wine-only runtime fallback paths.

The x86_64 macOS Wine runtime includes a Konyak-owned GPTK/D3DMetal loader shim
for user-imported GPTK payloads. The shim uses public CrossOver Wine loader
exports only; Konyak does not copy or implement CrossOver's proprietary
compatibility database.

## Repository Layout

- `apps/konyak`: Flutter desktop application.
- `packages/konyak_cli`: CLI backend consumed by Flutter.
- `docs`: architecture, runtime, and distribution notes.
- `scripts`: repository verification and developer tooling helpers.

## Development

All project commands run inside the Nix flake dev shell:

```sh
nix develop -c zsh -lc 'just verify'
```

Useful narrower checks:

```sh
nix develop -c zsh -lc 'just verify-governance'
nix develop -c zsh -lc 'just format-check'
nix develop -c zsh -lc 'just lint'
nix develop -c zsh -lc 'just flutter-test'
nix develop -c zsh -lc 'just cli-test'
```

See `AGENTS.md` for the engineering contract used by both human contributors
and coding agents.

## Data Model

Konyak bottles are stored as versioned JSON metadata managed by the CLI backend.
Runtime and platform-specific behavior must stay behind that boundary so Linux
and macOS behavior can evolve separately.

Default bottle locations are platform-specific:

- Linux: `~/.local/share/konyak/bottles` unless XDG or Konyak environment
  overrides are set.
- macOS: `~/Library/Application Support/Konyak/Bottles` unless Konyak
  environment or app settings overrides are set.

External plist metadata is not read or written.

## License

Konyak is distributed under the MIT License. See `LICENSE` for the full license
text and `THIRD_PARTY_NOTICES.md` for runtime component notices.
