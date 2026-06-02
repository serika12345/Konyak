## 1. Execution Environment

- Run all project commands inside the Nix flake dev shell.
- For one-shot commands, use `nix develop -c zsh -lc '<command>'`.
- After changing `.envrc` or `flake.nix`, run `direnv allow`.
- Do not run project tools such as `flutter`, `dart`, `just`, `swiftlint`,
  `swiftformat`, `wine`, `winetricks`, or Nix formatters directly from the host
  shell.
- If a command fails outside the dev shell, rerun it inside the dev shell before
  changing code.

## 2. Product Direction

- The application name is `Konyak`.
- The Flutter application lives in this repository as a subproject under
  `apps/konyak`.
- The first runtime target is arm64 macOS.
- The second runtime target is x86_64 Linux.
- Flutter talks to a CLI backend first. Keep this boundary simple and stable
  before considering FFI or embedded native libraries.
- Wine/Proton runtimes are managed by Konyak, bundled per channel where
  practical, and updateable by the application.
- Konyak-owned bottle metadata is the source of truth. External plist
  metadata is not accepted as live input; any future import path must be
  explicit import tooling rather than shared live metadata.
- GPTK, D3DMetal, Metal HUD/capture, and Rosetta settings are macOS-specific.
  Linux support must use Wine/Proton with Vulkan-oriented components such as
  DXVK and vkd3d-proton.

## 3. Priority Order

When instructions conflict, follow this order:

1. Mechanical gates (`just verify`, `just format-check`, `just lint`,
   `just test`, and narrower targets listed in this file)
2. Public CLI contracts and persisted data compatibility
3. Existing repository architecture
4. Design principles in this file
5. Local convenience

Do not violate a mechanical gate to satisfy a style preference.

## 4. Required Workflow

For every task, follow this sequence:

1. Read the relevant existing code before editing.
2. Identify the smallest safe change.
3. Add or update tests before implementation when behavior is observable and
   testable.
4. Implement the code.
5. Run the required verification commands for the change scope.
6. Do not finish while required commands are failing.

Use TDD as the default development loop:

1. Write a failing test that describes the intended behavior.
2. Implement the smallest change that makes it pass.
3. Refactor only while the test stays green.

## 5. Verification Matrix

### 5.1 Any repository or tooling change

- `just verify-governance`
- `just format-check`
- `just lint`

### 5.2 Flutter code change

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`

If visible behavior or navigation changes, add an integration or golden test
before the implementation when practical.

### 5.3 CLI backend change

- Add or update command-level tests before changing behavior.
- CLI output intended for Flutter must be JSON, versioned, and schema-stable.
- Human-readable output must not be parsed by Flutter.
- Add a `just cli-test` target before the first CLI implementation lands.

### 5.4 Swift platform change

- Keep changes scoped.
- Do not mass-format Swift platform code unless the task explicitly requires it.
- Run `just swift-lint` for Swift changes.
- Prefer extracting behavior into the CLI/backend boundary over adding SwiftUI
  dependencies.

## 6. Non-Negotiable Coding Constraints

- Prefer immutable data and pure functions for domain transformations.
- Keep I/O at explicit boundaries: filesystem, process execution, network, and
  platform services must not leak into domain logic.
- CLI I/O implementations must live under `packages/konyak_cli/lib/src/io`.
- I/O and routinely fallible business operations must return explicit
  Result/Either values or sealed result variants.
- Complete-constructor invariant violations may throw; ordinary I/O failure
  must not be represented by business-logic exceptions.
- fpdart is limited to CLI/domain code. Flutter UI must consume explicit app or
  CLI result models instead of importing fpdart.
- Model absence and failure explicitly. Do not hide failures behind default
  empty strings, empty lists, or broad catch-all branches.
- Validate all external data before it enters domain state. This includes plist
  imports, JSON, CLI stdout, filesystem scans, Wine command output, and network
  responses.
- Do not weaken linters, formatters, compiler options, tests, or verification
  scripts to make a change pass.
- Do not ignore failing tests or type errors.
- Avoid local lint disables. If a disable is unavoidable, scope it to the
  smallest line or block and include the reason in the code review.

## 7. Dart and Flutter Guidance

- Use `final` by default.
- Prefer small pure functions and immutable value objects.
- Keep widgets focused on rendering and orchestration.
- Put domain logic outside widgets.
- Keep process execution behind a platform service abstraction.
- Use explicit result types for fallible operations once the domain package is
  introduced.
- Prefer Riverpod for app state unless an architecture document replaces that
  decision.
- Use `flutter_lints` or stricter analysis settings from the start.
- Do not add dependencies before a test or concrete feature demonstrates the
  need.

## 8. CLI Boundary Rules

- Commands consumed by Flutter must support machine output with `--json`.
- JSON output must include a schema or contract version when it can be persisted
  or consumed across releases.
- Exit codes are part of the contract.
- stderr is for diagnostics, not application state.
- Process wrappers must preserve argv boundaries. Do not build shell commands by
  string concatenation unless launching a user-visible terminal is the feature.

## 9. Platform Rules

- Use XDG paths on Linux:
  - config: `~/.config/konyak`
  - data: `~/.local/share/konyak`
  - state/logs: `~/.local/state/konyak`
  - cache: `~/.cache/konyak`
- Use native macOS paths only behind the macOS platform service.
- Linux graphics defaults are Vulkan-oriented: DXVK for D3D8-D3D11 and
  vkd3d-proton for D3D12.
- macOS graphics defaults may keep GPTK/D3DMetal concepts, but those concepts
  must not appear in Linux UI or Linux domain defaults.

## 10. Completion Criteria

A coding task is not complete unless all of the following are true:

- The requested change is implemented.
- Tests were added or updated first when behavior was observable.
- Required format, lint, and test commands passed.
- New external-data paths are validated.
- No unrelated files were reformatted or refactored.

Final reports must include what changed, which commands ran, whether they
passed, and any remaining risks.
