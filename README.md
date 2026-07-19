# Konyak

## Product

Konyak manages Wine/Proton bottles and launches Windows applications from a
Flutter UI backed by a Dart CLI.

Konyak targets arm64 macOS first and x86_64 Linux second.
Konyak owns its bottle metadata, managed runtime installation, and update flows
instead of relying on live external plist metadata. The Flutter app lives in
`apps/konyak`, and the CLI backend lives in `packages/konyak_cli`.

Konyak is distributed under the MIT License.

## Project Goals

Konyak treats the Wine/CrossOver runtime supply chain as a core product
surface. Existing Wine wrapper projects are useful, but many distribute
prebuilt engines without publishing the complete recipe that produced the
runtime a user actually runs. Published upstream source is valuable, but it is
not the same as a reproducible runtime recipe that records dependencies,
patches, configure flags, bundled components, packaging layout, manifests, and
verification.

Konyak aims to keep those runtime recipes in Nix, update them continuously, and
verify them through CI against the current compatibility stack. The goal is for
users to get modern Wine/CrossOver-compatible runtimes from auditable inputs
instead of opaque engine archives.

Konyak's long-term goal is to provide a cross-platform, game-oriented Windows
compatibility environment across macOS and Linux. Each platform should use the
graphics stack that fits it best: Metal-oriented components on macOS and
Vulkan-oriented components such as DXVK and vkd3d-proton on Linux.

License transparency is part of the runtime contract. Konyak should avoid
runtime stacks that depend on unclear redistribution of commercial application
binaries or restrictive graphics components such as D3DMetal/GPTK. When a
component cannot be rebuilt, redistributed, or audited under clear terms, that
constraint should be explicit instead of hidden inside the wrapper.

This makes Konyak useful even before a polished GUI exists. Power users can
already benefit from CLI-driven bottles, reproducible builds, explicit runtime
manifests, reviewable artifacts, and CI-backed smoke verification. The Flutter
app should improve ergonomics without replacing the CLI and runtime recipes as
the source of truth.

Technical details are kept in developer documentation:

- [Compatibility profile authoring guide](docs/public/profiles/index.md):
  public manifest, validation, and schema-version documentation
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
