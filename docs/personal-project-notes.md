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
