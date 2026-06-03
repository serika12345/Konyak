# Personal Project Notes

These notes are intentionally separate from Konyak project TODOs.

## Functional Dart Lint Rules

Consider creating a separate personal project for Dart lint rules that promote
functional programming practices.

Initial rule ideas:

- Ban non-`final` local variable declarations in selected layers.
- Ban local variable reassignment in selected layers.
- Ban increment/decrement and compound assignment in selected layers.
- Prefer explicit `Option`/`Either`/sealed result handling at external-data and
  I/O boundaries.
- Keep mutable UI state and low-level I/O counters as explicit, configurable
  exceptions rather than global bans.

The likely implementation path is to prototype the rules in repository
governance scripts first, then move stable rules into a `custom_lint`-based Dart
analyzer plugin so they can surface in IDEs and `dart analyze`.

## Dart Code Metrics Replacement

Consider creating a separate personal project that reimplements the useful parts
of the discontinued `dart_code_metrics` package for current Dart and Flutter SDKs.

Initial scope:

- Function, method, class, and file size thresholds.
- Cyclomatic complexity and nesting depth checks.
- Unused file and unused declaration detection where analyzer APIs make it
  reliable.
- Configurable layer-specific thresholds for domain, I/O, platform, and UI code.
- Machine-readable output for CI plus concise console output for local use.

The first version can live as repository verification scripts to prove the rule
set against Konyak, then move into a standalone analyzer-aware tool or
`custom_lint` plugin once the behavior is stable.
