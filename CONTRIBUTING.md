# Contributing to Konyak

Konyak development is driven by the repository contract in `AGENTS.md`. Read it
before making changes.

## Environment

Run project tools inside the Nix flake dev shell:

```sh
nix develop -c zsh -lc 'just verify'
```

Do not run Flutter, Dart, Wine, Winetricks, SwiftLint, SwiftFormat, or Nix
formatters directly from the host shell for project work.

## Project Layout

- `apps/konyak`: Flutter desktop app.
- `packages/konyak_cli`: Dart CLI backend consumed by Flutter.
- `docs`: architecture, distribution, workflow, and TODO notes.
- `scripts`: repository verification and developer tooling.

The Flutter app should keep process execution, runtime state, and filesystem
integration behind the CLI boundary. Konyak-owned JSON metadata is the supported
bottle data model.

## Development Flow

- Read the relevant code before editing.
- Add or update tests first when behavior is observable.
- Keep Flutter UI behavior behind the CLI boundary where runtime state or
  process execution is involved.
- Keep JSON CLI contracts versioned and stable.
- Keep Linux and macOS runtime logic separated by explicit platform services.
- Avoid broad refactors unless they are required for the task.
- Update documentation when a product direction, persisted data contract,
  repository layout, or developer workflow changes.

## Checks

Run the checks that match the scope of the change. For repository-wide changes,
use:

```sh
nix develop -c zsh -lc 'just verify-governance'
nix develop -c zsh -lc 'just format-check'
nix develop -c zsh -lc 'just lint'
```

For Flutter changes, also run:

```sh
nix develop -c zsh -lc 'just flutter-format-check'
nix develop -c zsh -lc 'just flutter-analyze'
nix develop -c zsh -lc 'just flutter-test'
```

For CLI changes, add command-level tests and run:

```sh
nix develop -c zsh -lc 'just cli-test'
```

## Pull Requests

Describe the behavior change, the checks you ran, and any remaining risks.
Include screenshots for visible UI changes.
