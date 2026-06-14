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
- macOS runtime bug fixes must be coordinated with the
  `runtime/konyak-macos-runtime` submodule. If a fix changes runtime files,
  component archives, release manifests, loader behavior, or bundled runtime
  dependencies, update the submodule-side build/release tooling together with
  the parent repository consumer contracts.
- Keep the runtime submodule artifacts and source manifests as the source of
  truth for macOS runtime dependencies. Do not add parent-repository Nix flake
  or dev-shell dependencies just to supply runtime libraries; consume the
  submodule-produced runtime stack instead.
- Konyak-owned bottle metadata is the source of truth. External plist
  metadata is not accepted as live input; any future import path must be
  explicit import tooling rather than shared live metadata.
- GPTK, D3DMetal, Metal HUD/capture, and Rosetta settings are macOS-specific.
  Linux support must use Wine/Proton with Vulkan-oriented components such as
  DXVK and vkd3d-proton.

## 3. Priority Order

When instructions conflict, follow this order:

1. Mechanical gates (`just verify`, `just verify-safety`, `just format-check`,
   `just lint`, `just test`, and narrower targets listed in this file)
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

When local build plus execution or smoke verification proves a runtime,
packaging, launcher, or other CI-relevant workflow, update the corresponding
GitHub Actions workflow in the same change so CI exercises the same path as
closely as practical. If Actions cannot mirror the local execution, document the
reason in `docs/progress.md` and leave an explicit TODO or follow-up before
finishing.

Runtime Actions must keep rerun units narrow. Do not combine expensive Wine
runtime builds, DXMT builds, binary component packaging, release metadata,
smoke verification, and publish work into one monolithic job. A failed smoke,
metadata, component packaging, or DXMT job must be rerunnable without forcing a
successful Wine runtime build to run again.
Jobs that need a built Wine runtime after `build-wine-runtime` must download and
use the uploaded Wine runtime artifact. They must not depend on the CrossOver
Wine derivation in a way that can rebuild CrossOver during a downstream rerun.

Use TDD as the default development loop:

1. Write a failing test that describes the intended behavior.
2. Implement the smallest change that makes it pass.
3. Refactor only while the test stays green.

### 4.1 Execution Path SSOT

- Application and CLI behavior verification must use the same public execution
  path that Konyak uses at runtime. Prefer Flutter-triggered CLI calls,
  `dart run bin/konyak.dart ... --json`, or maintained smoke scripts that wrap
  those contracts.
- For macOS winetricks verification, the source of truth is
  `run-winetricks <bottle-id> --verb <verb> --json`, which must produce and run
  a `macosWinetricks` program request. The maintained local CLI smoke entry
  point is `scripts/run_macos_runtime_cli_smoke.zsh`.
- Do not manually invoke packaged Wine executables such as `wine`, `wine64`,
  `wineserver`, or `wineboot`, and do not manually invoke packaged
  `winetricks`, to prove application behavior.
- Do not create ad hoc `WINEPREFIX` values.
- Low-level runtime checks may inspect artifacts with tools such as `otool` or
  run repository-maintained runtime scripts under `runtime/konyak-macos-runtime`
  when the artifact layout or loader contract itself is the behavior under
  test. If a new low-level runtime execution path is needed, add it as a
  maintained script and document why the app/CLI path cannot cover that case in
  `docs/progress.md`.
- Do not suppress Wine Mono/MSHTML addon probing with `mscoree,mshtml=` to make
  prefix initialization, bottle creation, runtime validation, winetricks, or CI
  smoke pass. The runtime must instead package the Wine-expected addon payloads
  and prove the normal installer/probe path succeeds locally through the
  application-owned CLI route.
- macOS Wine addon payloads must match the versions and filenames compiled into
  the packaged Wine source. Parent runtime completeness checks must require the
  exact Mono and Gecko MSI payload paths instead of accepting marker files or
  addon directories.

## 5. Roadmap and Progress Discipline

Before starting implementation, refactoring, architecture work, runtime
packaging work, or major repository-policy work, read the relevant entries in
`docs/todo.md` and the current work state in `docs/progress.md`.

Use these files for different responsibilities:

- `docs/todo.md` tracks implementation milestones, deferred work, and large
  product goals.
- `docs/progress.md` tracks completed milestones, current active work, why that
  work is being done, verification already performed, remaining work, and the
  next action needed to continue after context is lost.
- Architecture documents such as `docs/flutter-architecture-plan.md` track
  stable design decisions and system shape.

Project progress must be understandable from documentation alone. Do not rely
on chat history or git history as the only record of what is currently being
advanced or why.

When starting, pausing, blocking, superseding, or completing TODO-backed
implementation, refactoring, architecture work, runtime/submodule work, or
major documentation/policy work, update the timestamped
`Current Work Snapshot` in `docs/progress.md` in the same change. Include:

- timestamp in `YYYY-MM-DD HH:MM JST`
- state: `planned`, `in_progress`, `paused`, `blocked`, `completed`, or
  `superseded`
- related TODO, design document, issue, branch, and latest commit when known
- the purpose of the work
- completed work
- remaining work
- next action
- verification performed or deliberately skipped

Do not leave stale `in_progress` entries behind. If work is handed off,
interrupted, or intentionally stopped without completion, mark it `paused` or
`blocked` with the exact next action needed to resume.

When a change completes, invalidates, or materially changes a roadmap item,
update the appropriate document in the same change:

- implementation progress belongs in `docs/todo.md`
- current state, completed milestone summaries, and handoff notes belong in
  `docs/progress.md`
- durable architecture decisions belong in the relevant design document

Do not mark a TODO item complete until the implementation, tests or fixtures,
and required verification have actually been completed. Do not leave a TODO
item marked incomplete when the implementation and verification for that item
are complete.

When the user asks to continue work without naming a specific task, use
`docs/progress.md` first, then `docs/todo.md`, to identify the safest next
coherent step. Prefer the earliest unfinished relevant TODO unless the current
work snapshot points to a more specific continuation.

## 6. Verification Matrix

### 6.1 Any repository or tooling change

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

### 6.2 Flutter code change

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`

If visible behavior or navigation changes, add an integration or golden test
before the implementation when practical.

### 6.3 CLI backend change

- Add or update command-level tests before changing behavior.
- CLI output intended for Flutter must be JSON, versioned, and schema-stable.
- Human-readable output must not be parsed by Flutter.
- Add a `just cli-test` target before the first CLI implementation lands.

### 6.4 Swift platform change

- Keep changes scoped.
- Do not mass-format Swift platform code unless the task explicitly requires it.
- Run `just swift-lint` for Swift changes.
- Prefer extracting behavior into the CLI/backend boundary over adding SwiftUI
  dependencies.

## 7. Non-Negotiable Coding Constraints

- Prefer immutable data and pure functions for domain transformations.
- Keep I/O at explicit boundaries: filesystem, process execution, network, and
  platform services must not leak into domain logic.
- CLI I/O implementations must live under `packages/konyak_cli/lib/src/io`.
- I/O and routinely fallible business operations must return explicit
  Result/Either values or sealed result variants.
- Expected absence in CLI/domain logic must use Option rather than nullable
  domain values.
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

## 8. Dart and Flutter Guidance

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

## 9. CLI Boundary Rules

- Commands consumed by Flutter must support machine output with `--json`.
- JSON output must include a schema or contract version when it can be persisted
  or consumed across releases.
- Exit codes are part of the contract.
- stderr is for diagnostics, not application state.
- Process wrappers must preserve argv boundaries. Do not build shell commands by
  string concatenation unless launching a user-visible terminal is the feature.

## 10. Platform Rules

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

## 11. Completion Criteria

A coding task is not complete unless all of the following are true:

- The requested change is implemented.
- Tests were added or updated first when behavior was observable.
- Required format, lint, and test commands passed.
- New external-data paths are validated.
- Any runtime, packaging, launcher, or CI-relevant behavior that was verified by
  local build plus execution or smoke testing is reflected in the corresponding
  GitHub Actions workflow, or the documented exception and follow-up are
  recorded.
- `docs/progress.md` and `docs/todo.md` reflect any changed current state,
  completed milestone, or roadmap item.
- No unrelated files were reformatted or refactored.

Final reports must include what changed, which commands ran, whether they
passed, and any remaining risks.
