# Konyak App

Flutter desktop UI for Konyak.

The app lives under `apps/konyak` and talks to
`packages/konyak_cli` through versioned JSON CLI contracts. Runtime
installation, process execution, filesystem access, and persisted bottle
metadata should stay behind that CLI boundary.

This app is developed from the repository root through the Nix dev shell:

```sh
nix develop -c zsh -lc 'just verify'
```

Useful Flutter-specific checks:

```sh
nix develop -c zsh -lc 'just flutter-format-check'
nix develop -c zsh -lc 'just flutter-analyze'
nix develop -c zsh -lc 'just flutter-test'
```

Feature work must follow the repository TDD workflow in `../../AGENTS.md`.
