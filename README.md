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

## Agent Workflows

Refactoring work is tracked as large milestones, small milestones, and PR
gates in [docs/todo.md](docs/todo.md). Current handoff state lives in
[docs/progress.md](docs/progress.md).

Common agent action commands:

- `/advance-large`: advance the current large milestone on a dedicated branch,
  open a draft PR at the review gate, then stop.
- `/advance-pr`: advance only the next unfinished `PR Gate` in `docs/todo.md`,
  open a draft PR, then stop.
- `/advance-small`: advance the next coherent small milestone in the active
  gate, commit and push the verified step, then stop.
- `/review-gate`: summarize the current branch for review without implementing
  more work.
- `/konyak-status`: report branch state, worktree state, active milestone, and
  recommended next action without modifying files.

Repo-scoped skills under `.agents/skills` mirror these commands for Codex IDE
selection, such as `$konyak-advance-large` and `$konyak-advance-pr`.

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
