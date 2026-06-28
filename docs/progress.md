# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-06-28 20:53 JST
- State: `completed`
- Branch: `main`
- Active work: tighten the domain-facing `ProgramRunRequest` boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `de08e9f` (`Track functional core boundary follow-ups`).
- Purpose: replace the remaining primitive constructor surface for
  program-run requests with typed domain value objects before moving JSON
  projection out of domain models.
- Completed work: read the current roadmap/progress state and inspected
  `ProgramRunRequest`, `ProgramRunPlanner`, existing domain value objects,
  and program-run request builder call sites; added red coverage for immutable
  `ProgramRunArguments`; added governance that rejects primitive
  `ProgramRunRequest` constructor fields; changed `ProgramRunRequest` to
  require `BottleId`, `ProgramPath`, `RunnerKind`, `ProgramExecutable`,
  `ProgramRunArguments`, `ProgramLogPath`, and typed working-directory values;
  updated domain, platform, and I/O request builders plus direct tests to
  construct typed requests; moved I/O, logging, and JSON call sites to read
  `request.arguments.value`.
- Remaining work: broader primitive tightening remains for planner entry
  points such as program path, bottle command, winetricks verb, process id,
  and registry version values.
- Next action: continue the functional-core boundary work by typing
  `ProgramRunPlanner` entry commands or by moving domain `toJson` projection
  once the request API is stable.
- Verification: observed `just verify-governance` fail before implementation
  because `ProgramRunRequest` still exposed primitive constructor fields;
  observed `cd packages/konyak_cli && dart test test/domain_value_objects_test.dart`
  fail before implementation because `ProgramRunArguments` did not exist;
  after implementation, `cd packages/konyak_cli && dart analyze --fatal-infos`,
  focused domain value/immutability tests, `just verify-governance`, and
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 20:08 JST
- State: `completed`
- Branch: `main`
- Active work: split `program_run_request_builders.dart` into responsibility
  libraries.
- Related TODO: `docs/todo.md` deferred
  `program_run_request_builders.dart` split.
- Latest commit: `a2e413c` (`Remove CLI StateError fallbacks`).
- Purpose: replace the remaining production large-file governance baseline for
  the pure program-run request-builder table with explicit Linux, macOS,
  terminal, and command-support domain libraries.
- Completed work: read the current roadmap/progress state, confirmed the
  1002-line request-builder file was only imported by `ProgramRunPlanner`;
  moved Linux request builders and Linux runtime environment assembly into
  `program_run_linux_requests.dart`; moved macOS request builders and macOS
  runtime environment assembly into `program_run_macos_requests.dart`; moved
  terminal command request rendering into `program_run_terminal_requests.dart`;
  moved small command validators into `program_run_command_support.dart`; left
  `program_run_request_builders.dart` as the stable export boundary; removed
  the production large-file governance baseline and added governance for the
  exact split export shape; removed the completed TODO item.
- Remaining work: none for this slice.
- Next action: continue with the next deferred backend cleanup, likely moving
  JSON `toJson` projection out of domain models where compatibility permits.
- Verification: observed `just verify-governance` fail before implementation
  because `program_run_request_builders.dart` still exceeded the production
  line limit after its baseline was removed; after implementation,
  `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just verify-governance`, `just verify-architecture`, `just cli-test`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 19:48 JST
- State: `completed`
- Branch: `main`
- Active work: audit and remove domain `StateError` paths that mask expected
  absence or typed failure.
- Related TODO: `docs/todo.md` deferred domain `throw StateError` /
  `getOrElse(() => throw ...)` audit.
- Latest commit: `45c60ee` (`Remove no-op home detail wrapper`).
- Purpose: keep domain logic from encoding expected unsupported paths,
  optional manifest data, and malformed archive plans as runtime exceptions.
- Completed work: identified production `StateError` paths in program argument
  selection, runtime install planning, runtime install-source construction,
  runtime source archive bundle projection, and runtime stack source-manifest
  I/O adapters; changed unsupported program paths to `Option.none`, archive
  bundle projection to `RuntimeStackSourceArchiveBundleResult`, and source
  manifest adapters to explicit invalid-manifest branches; added tests for the
  typed branches and governance that rejects `StateError` in
  `packages/konyak_cli/lib/src`; removed the completed TODO item.
- Remaining work: none for this slice.
- Next action: continue with the next deferred backend cleanup, likely
  splitting `program_run_request_builders.dart`.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart` fail before implementation because
  `wineArgumentsForProgramPath` returned a `List<String>` and lacked
  `Option` methods; observed `just verify-governance` fail before
  implementation on the existing domain `StateError`; after implementation,
  focused domain tests, `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just verify-governance`, `just verify-architecture`, `just cli-test`,
  `just verify-safety`, `just format-check`, and `just lint` passed; final
  `rg "throw StateError|getOrElse\\(\\(\\) => throw|StateError\\("
  packages/konyak_cli/lib/src -n` returned no matches.

- Timestamp: 2026-06-28 19:25 JST
- State: `completed`
- Branch: `main`
- Active work: audit Flutter UI for no-op wrapper widgets after the home
  contract split.
- Related TODO: `docs/todo.md` deferred Flutter large UI split.
- Latest commit: `513bcf1` (`Replace duplicate known runtime state`).
- Purpose: remove Flutter UI boundaries that only forward props without owning
  rendering, state, layout, action selection, or a stable public contract.
- Completed work: inspected the current home/detail/sidebar widgets and small
  reusable UI files; kept semantic or styled components such as
  `KonyakHomeSidebarPane`, `PinnedProgramsSection`, `KonyakBottomButton`,
  `KonyakToolbarAction`, and `KonyakToggle`; removed the no-op
  `KonyakHomeDetailPane` wrapper by having `KonyakHome` render
  `KonyakBottleDetail` directly.
- Remaining work: broader lower-level Flutter view-model/action-selection
  cleanup remains for `sidebar.dart`, `program_configuration_view.dart`, and
  `bottle_configuration_view.dart`.
- Next action: continue with the next small Flutter view-model extraction when
  requested.
- Verification: `just flutter-format-check`, `just flutter-analyze`,
  `just flutter-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint` passed; the first
  `just verify-governance` run failed because the deleted wrapper was still in
  the constructor-prop governance baseline, then passed after the baseline was
  updated to keep the active `KonyakHome` and `KonyakBottleDetail` checks.

- Timestamp: 2026-06-28 19:09 JST
- State: `completed`
- Branch: `main`
- Active work: collapse Flutter home props into responsibility-scoped contract
  objects before introducing any state-management library.
- Related TODO: `docs/todo.md` deferred Flutter large UI split.
- Latest commit: `513bcf1` (`Replace duplicate known runtime state`).
- Purpose: make the `KonyakHome`, `KonyakHomeDetailPane`, and
  `KonyakBottleDetail` boundaries express view state, menu actions, bottle
  actions, program actions, and winetricks actions explicitly instead of
  passing dozens of flat props through every layer.
- Completed work: added immutable `KonyakHomeViewState` and
  `KonyakHomeDetailState` contracts plus scoped action contracts for menu,
  bottle, program, winetricks, and local navigation; moved `BottleDetailMode`
  to a standalone boundary enum; updated `home_loader.dart` to compose the
  contracts from existing state and callbacks without adding Riverpod,
  Provider, or `InheritedWidget`; reduced the direct constructor props for the
  three target widgets to contract objects; and added governance that fails if
  those constructors grow past six direct props again.
- Remaining work: App Settings dialog async state still uses separate loading,
  error, and install flags; lower-level Flutter view-model/action-selection
  cleanup remains for `sidebar.dart`, `program_configuration_view.dart`, and
  `bottle_configuration_view.dart`.
- Next action: continue with the App Settings dialog runtime async state or the
  next small Flutter view-model extraction when requested.
- Verification: observed `just verify-governance` fail before implementation
  because `KonyakHome` still had 37 direct props; added
  `test/app/home_contracts_test.dart` and observed it fail before the contract
  file existed; after implementation, focused home contract/navigation tests,
  representative widget flows, `flutter analyze --fatal-infos`, and
  `just verify-governance` passed; final `just verify` and
  `just verify-governance && just verify-architecture` passed; final
  `git diff --check HEAD` passed.

- Timestamp: 2026-06-28 18:49 JST
- State: `completed`
- Branch: `main`
- Active work: replace duplicate known-runtime list/load flags in the Flutter
  home loader.
- Related TODO: none; this is a focused duplicate-state cleanup.
- Latest commit: `a7aac13` (`Derive Flutter runtime stack status`).
- Purpose: remove the separate `knownRuntimes` list plus
  `hasLoadedKnownRuntimes` boolean so the home loader cannot represent
  contradictory runtime capability state.
- Completed work: added a sealed `KnownRuntimesState` with pending and loaded
  variants; updated `KonyakHomeLoaderState`, runtime loading/install flows, and
  settings-dialog composition to derive runtime lists and loading state from
  that single state object; and added focused tests proving pending and loaded
  empty runtime lists remain distinct while loaded lists are immutable
  snapshots.
- Remaining work: none for this slice. Broader app settings dialog async state
  and other view-model cleanup remain separate follow-up candidates.
- Next action: continue with the next small duplicate-state or view-model
  cleanup when requested.
- Verification: observed
  `cd apps/konyak && flutter test
  test/home_loader/known_runtimes_state_test.dart` fail before implementation;
  after implementation, that test passed, plus focused widget/runtime CLI tests
  for runtime capability loading, settings runtime install, startup managed
  runtime prompts, and runtime CLI client contracts passed; final
  `just verify` and `git diff --check HEAD` passed.

- Timestamp: 2026-06-28 18:34 JST
- State: `completed`
- Branch: `main`
- Active work: remove derived runtime stack status from Flutter summary state.
- Related TODO: none; this is a focused follow-up after auditing duplicate
  state.
- Latest commit: `2ebb35a` (`Remove CLI injected runner I/O defaults`).
- Purpose: keep Flutter runtime summaries from storing values that are already
  computable from stack components and backend missing entries, while
  preserving the existing CLI JSON contract.
- Completed work: changed `RuntimeStackSummary.isComplete`,
  `RuntimeStackBackendSummary.isAvailable`, and
  `RuntimeStackComponentSummary.isInstalled` into getters derived from
  component/backend details; kept the JSON parser accepting those fields as
  contract data but rejecting payloads where they contradict the detailed
  missing-path fields; and updated focused runtime view-model/control tests to
  construct state through the derived fields.
- Remaining work: none for this slice. The separate `knownRuntimes` /
  `hasLoadedKnownRuntimes` loader-state cleanup was completed by the
  2026-06-28 18:49 snapshot above.
- Next action: continue with the next small duplicate-state or state-shape
  cleanup when requested.
- Verification: observed the new runtime-list contract tests fail before
  implementation; after implementation, focused
  `cd apps/konyak && flutter test test/cli/runtime_list_contract_test.dart
  test/app/app_settings_runtime_view_model_test.dart
  test/app/bottle_runtime_control_availability_test.dart` passed; final
  `just verify` and `just flutter-test` passed.

- Timestamp: 2026-06-28 17:49 JST
- State: `completed`
- Branch: `main`
- Active work: remove concrete Dart I/O defaults from the internal injectable
  CLI runner.
- Related TODO: `docs/todo.md` deferred
  `program_run_request_builders.dart` split; domain impossible-state throws;
  domain JSON projection extraction.
- Latest commit: `f8ad003` (`Retire domain part root boundary`).
- Purpose: keep `package:konyak_cli/konyak_cli.dart` thin while making
  `src/cli/cli_injected_runner.dart` a real injection boundary and moving
  default Dart I/O composition fully into `src/cli/cli_default_runner.dart`.
- Completed work: read `AGENTS.md`, `docs/todo.md`, `docs/progress.md`,
  status/diff, and the current CLI facade/default/injected runner shape; changed
  `src/cli/cli_injected_runner.dart` to accept an explicit
  `CliCommandContext` plus streaming dependencies instead of constructing
  `DartIo*` defaults; moved default `DartIoBottleProgramRepository`,
  `DartIoProgramMetadataExtractor`,
  `DartIoProgramGraphicsBackendHintsInspector`,
  `DartIoWinetricksVerbRepository.current()`, `currentProgramRunPlanner()`,
  `DartIoAsyncProgramRunner`, `DartIoAsyncProgramMetadataExtractor`, and
  `DartIoHostProcessSnapshotReader` composition into
  `src/cli/cli_default_runner.dart`; added streaming installer interfaces so
  the injected runner no longer type-checks concrete Dart I/O installers; moved
  CLI contract tests to a test-local injection helper with explicit Dart I/O
  injection where behavior needs it; and added governance that fails if
  `cli_injected_runner.dart` regains `DartIo`, `currentProgramRunPlanner`, or
  direct `../io/` composition.
- Remaining work: none for this slice. Existing deferred domain throw removal,
  JSON projection extraction, and request-builder split remain.
- Next action: continue with `docs/todo.md`, starting with domain
  impossible-state throws or domain JSON projection extraction.
- Verification: governance-first failure was observed before implementation;
  focused `cd packages/konyak_cli && dart analyze --fatal-infos` passed;
  focused `cd packages/konyak_cli && dart test test/public_facade_test.dart
  test/cli_contract_test.dart` passed; final `just verify`,
  `just verify-governance && just verify-architecture`, and
  `git diff --check HEAD` passed.

- Timestamp: 2026-06-28 17:20 JST
- State: `completed`
- Branch: `main`
- Active work: split the package-root CLI facade from the internal injectable
  CLI runner.
- Related TODO: `docs/todo.md` deferred
  `program_run_request_builders.dart` split; domain impossible-state throws;
  domain JSON projection extraction.
- Latest commit: `f8ad003` (`Retire domain part root boundary`).
- Purpose: make `package:konyak_cli/konyak_cli.dart` usable without exposing
  repository/I/O/platform dependency types through `runCli` or
  `runCliStreaming`, while keeping dependency injection available inside
  `src/cli`.
- Completed work: added `src/cli/cli_facade.dart` with simple
  `List<String>`-only public `runCli` and `runCliStreaming`; moved the
  dependency-heavy runner into `src/cli/cli_injected_runner.dart`; moved
  default Dart I/O composition into `src/cli/cli_default_runner.dart`;
  simplified `bin/konyak.dart` to call the default runner with a progress sink;
  kept `cli_commands.dart` focused on `CliCommandContext` and command
  dispatch; changed `ProgramGraphicsBackendHintsInspector.inspect` to accept
  `ProgramPath`; added a public facade regression test; and strengthened
  governance for exact root exports, exact facade signatures, and no `DartIo`
  references in `cli_commands.dart`.
- Remaining work: none for this slice. Existing deferred domain throw removal,
  JSON projection extraction, and request-builder split remain.
- Next action: continue with `docs/todo.md`, starting with domain
  impossible-state throws or domain JSON projection extraction.
- Verification: focused `cd packages/konyak_cli && dart analyze
  --fatal-infos`, `cd packages/konyak_cli && dart test
  test/public_facade_test.dart`, and `just verify-governance` passed; final
  `just verify`, `just verify-governance && just verify-architecture`, and
  `git diff --check HEAD` passed.

- Timestamp: 2026-06-28 16:54 JST
- State: `completed`
- Branch: `main`
- Active work: narrow the Konyak CLI package-root public exports and move the
  graphics-backend hint inspector behind the CLI command context.
- Related TODO: `docs/todo.md` deferred
  `program_run_request_builders.dart` split; domain impossible-state throws;
  domain JSON projection extraction.
- Latest commit: `f8ad003` (`Retire domain part root boundary`).
- Purpose: keep the post-handwritten-`part` design moving toward explicit
  public contracts and internal composition roots without reintroducing giant
  barrels or handler-side concrete I/O construction.
- Completed work: reduced `packages/konyak_cli/lib/konyak_cli.dart` to CLI
  facade and domain-contract exports; moved CLI binary and CLI tests to
  explicit internal imports for repository/I/O/platform fixtures; added a
  `ProgramGraphicsBackendHintsInspector` domain port; injected that port
  through `CliCommandContext`; and added governance for the package-root export
  allowlist.
- Remaining work: none for this slice. `program_run_request_builders.dart`,
  domain impossible-state throws, and domain JSON projection extraction remain
  deferred design debt.
- Next action: continue with `docs/todo.md`, starting with domain
  impossible-state throws or domain JSON projection extraction before splitting
  `program_run_request_builders.dart`.
- Verification: focused regression
  `cd packages/konyak_cli && dart test test/cli_contract_test.dart -n
  "suggest-graphics-backend --json uses the injected inspector"`, CLI analyzer
  `cd packages/konyak_cli && dart analyze --fatal-infos`, and
  `just verify-governance` passed; final `just verify`,
  `just verify-architecture`, and `git diff --check HEAD` passed.

- Timestamp: 2026-06-28 16:31 JST
- State: `completed`
- Branch: `main`
- Active work: replace the post-`part` transitional giant libraries with
  standalone responsibility libraries.
- Related TODO: `docs/todo.md` deferred Dart `part` root library boundary
  cleanup.
- Latest commit: `f8ad003` (`Retire domain part root boundary`).
- Purpose: finish the architecture correction by replacing the temporary
  pasted backend/client/home-loader files with explicit Dart import boundaries.
- Completed work: split `src/io/konyak_cli_backend.dart` back into standalone
  CLI, I/O, repository, platform, storage, and shared libraries; removed the
  backend file; split the Flutter CLI client into process runner, launch
  config, parsers, result types, and command extensions; split the home loader
  into loader state and bottle/program/runtime/settings/winetricks/process
  action libraries; kept generated Freezed/JSON `part` as the only production
  `part` use; removed repository constructor defaults for
  `DartIoProgramMetadataExtractor`; and strengthened governance against
  pasted part markers, large transitional files, and repository-side concrete
  I/O defaults.
- Remaining work: no transitional backend/client/home-loader giant remains.
  Existing baseline files over 1000 lines are limited to generated Flutter
  localizations, centralized value-object declarations, and the pure program
  run request-builder table.
- Next action: continue with `docs/todo.md`, starting with domain impossible
  state throws or domain JSON projection extraction.
- Verification: `just format-check`,
  `just verify-governance && just verify-architecture &&
  just konyak-lints-test`, `just cli-analyze && just flutter-analyze`,
  focused CLI pinned-program icon regression test, `just cli-test`, and
  final `just verify` passed.

- Timestamp: 2026-06-28 15:10 JST
- State: `completed`
- Branch: `main`
- Active work: retire the Konyak CLI domain `part` root-library boundary.
- Related TODO: `docs/todo.md` deferred Dart `part` root library boundary
  cleanup.
- Latest commit: `77f75bb` (`Strengthen custom lint domain boundaries`).
- Purpose: replace the apparent Dart `part` boundary with real standalone
  libraries for hand-written `packages/konyak_cli/lib/src/domain/**` code.
- Completed work: strengthened `konyak_no_domain_part_of_root` so any
  hand-written domain `part of` is rejected; removed the domain part baseline;
  removed every `part 'src/domain/...';` from `konyak_cli.dart`; converted the
  hand-written domain files to explicit imports; moved domain ports/helpers out
  of I/O/shared root-private files; moved concrete runtime catalog classes back
  to I/O composition; and moved PE graphics hint signal extraction to I/O so
  domain receives typed signals instead of PE bytes.
- Remaining work: none for the domain `part` baseline; non-domain CLI/I/O/
  platform files still use the root part library and should be reduced in later
  slices.
- Next action: continue with the remaining design-boundary backlog in
  `docs/todo.md`, starting with concrete `DartIo*` repository defaults or the
  remaining non-domain root part library.
- Verification: `just format-check && just cli-analyze &&
  just verify-governance && just verify-architecture &&
  just konyak-lints-test` and `just verify` passed.

- Timestamp: 2026-06-28 13:58 JST
- State: `completed`
- Branch: `main`
- Active work: make the custom lint I/O/domain boundary hardening reflect real
  architectural boundaries.
- Related TODO: none; this is a correction to the active custom lint/governance
  enforcement change.
- Latest commit: `2612436` (`Move external payload parsers to IO`).
- Purpose: prevent `part`-wide `dart:io` imports and request callbacks from
  leaving platform/I/O behavior reachable from domain files while the new lint
  rules appear green.
- Completed work: added failing fixtures for `Platform.*`, `DartIo*` domain
  implementation leaks, file/process I/O references, and domain
  serialization-boundary use; extended `konyak_no_domain_io` to catch those
  cases; moved current runtime catalog/planner construction to I/O factories;
  moved runtime package installer hooks and progress sinks to `src/io`; and
  moved `DartIoRuntimeUpdateChecker`/`DartIoAppUpdateChecker` out of domain.
- Remaining work: none for this correction slice.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `just konyak-lints-analyze`, `just konyak-lints-test`,
  `just verify-governance`, `just cli-custom-lint`,
  `just format-check && just lint && just verify-safety && just test`, and
  `just verify-architecture` passed.

- Timestamp: 2026-06-28 13:21 JST
- State: `completed`
- Branch: `main`
- Active work: strengthen custom lint and governance for domain I/O and
  nullable sentinel flows.
- Related TODO: none; this is a repository policy enforcement hardening.
- Latest commit: `2612436` (`Move external payload parsers to IO`).
- Purpose: make the analyzer/custom-lint path catch domain I/O leaks and the
  nullable sentinel Result/Option patterns that regex/script checks can miss.
- Completed work: added fixture-driven tests for the lint package; added
  custom lint rules for domain I/O API references and nullable sentinel flow;
  connected the new rules to CLI/Flutter analysis options and governance; and
  moved the currently detected runtime package installer/digest I/O references
  out of domain code.
- Remaining work: none for this enforcement slice.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `just konyak-lints-analyze`, `just konyak-lints-test`, and
  `just verify-governance && just cli-custom-lint` passed; the full
  repository/tooling gate
  `just verify-architecture && just format-check && just lint &&
  just verify-safety && just test && git diff --check` passed.

- Timestamp: 2026-06-28 12:11 JST
- State: `completed`
- Branch: `main`
- Active work: move nullable/reassignment governance from external scripts to
  `custom_lint`.
- Related TODO: none; this is a coding-standard enforcement correction.
- Latest commit: `2612436` (`Move external payload parsers to IO`).
- Purpose: enforce the domain coding rules through Dart analyzer/custom lint
  instead of separate AST or regex scripts, while keeping I/O and adapter
  boundary exceptions explicit.
- Completed work: added the internal `tools/konyak_lints` plugin with custom
  lint rules for non-boundary `null`/nullable usage, nullable bridge helpers,
  Result/Either failure collapse into `Option.none()`, domain reassignment,
  `var`, increment/decrement, nested conditionals, and parameter mutation;
  connected `custom_lint` to the CLI and Flutter packages;
  made `just lint` run custom lint for both packages and analyzer for the lint
  package itself; replaced the external domain reassignment/nullable regex
  governance checks with custom lint configuration checks; removed
  `scripts/verify_domain_reassignment.dart`; and documented the
  functional/domain coding standards in `AGENTS.md`.
- Remaining work: none for this enforcement slice.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `tools/konyak_lints` analyzer, CLI `custom_lint`, Flutter
  `custom_lint`, `just cli-analyze`, `just flutter-analyze`,
  `just verify-governance`, `just format-check`, `just lint`,
  `just verify-safety`, `just test`, and `git diff --check` passed.

- Timestamp: 2026-06-28 07:29 JST
- State: `completed`
- Branch: `main`
- Active work: isolate external payload nullable helpers out of shared/domain
  packaging.
- Related TODO: none; this is a focused architecture correction after nullable
  and reassignment hardening.
- Latest commit: `4b1e91e` (`Remove nullable domain control flow`).
- Purpose: keep `packages/konyak_cli/lib/src/shared` and domain files from
  hosting I/O-only decoded payload, `Map<String, Object?>`, and nullable bridge
  helpers; place external byte/text/JSON parsing behind `src/io` boundaries.
- Completed work: used separate audit, implementation, and final audit
  sub-agents; moved decoded payload, process-output, byte-reading, null-bridge,
  PE/LNK/registry/winetricks/Wine process, and external launch record parsing
  helpers into `src/io`; removed those helpers from `src/shared`; removed the
  external payload parser files from `src/domain`; updated the `part`
  declarations; replaced the remaining domain runner dependency on the I/O
  null bridge with local non-null parsing; strengthened governance so shared
  and non-I/O packages cannot regain those external payload helpers.
- Remaining work: none for this slice. Domain JSON `toJson` contract renderers
  remain as the existing explicit compatibility boundary.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: audit sub-agent completed, implementation sub-agent completed,
  final audit sub-agent completed with no major findings,
  `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just verify-governance`, `just format-check`, `just verify-safety`,
  `just lint`, `just cli-test`, and `git diff --check` passed.

- Timestamp: 2026-06-28 06:43 JST
- State: `completed`
- Branch: `main`
- Active work: remove remaining domain/control-flow nullable usage after the
  nullable-boundary correction.
- Related TODO: none; this is a focused correction to the previous nullability
  hardening.
- Latest commit: `7af4274` (`Restrict nullable usage to external boundaries`).
- Purpose: remove the remaining `null`/nullable escape hatches from PE parsing,
  registry parsing, process/winetricks/shortcut parsing, and program run
  planning so absence is represented by `Option` instead of nullable control
  values.
- Completed work: converted PE image/icon/version parsing, shortcut parsing,
  registry parsing, winetricks parsing, Wine process metadata parsing, and
  program run planning to `Option`-based absence handling without `null`,
  nullable fields, or nullable temporary control values; propagated
  `Option<int>` and `Option<String>` through macOS/terminal/winetricks request
  builders; moved nullable byte/string lifting behind shared helper functions;
  removed the corrected domain files from the nullable-boundary governance
  allowlist so regressions fail the gate.
- Remaining work: none for this correction slice. CLI parser/UI adapter
  nullable checks remain only at external input/framework boundaries.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `cd packages/konyak_cli && dart analyze --fatal-infos`,
  targeted `rg` searches for `null`/nullable/`??` in the corrected domain
  parser and planner files, `just verify-governance`, `just format-check`,
  `just verify-safety`, `just cli-test`, `just lint`, and `git diff --check`
  passed.

- Timestamp: 2026-06-28 05:54 JST
- State: `completed`
- Branch: `main`
- Active work: prohibit reassignment in CLI domain logic.
- Related TODO: none; this is a focused code-quality hardening requested after
  the nullable boundary cleanup.
- Latest commit: `7af4274` (`Restrict nullable usage to external boundaries`).
- Purpose: keep domain transformations immutable and pattern-oriented by
  removing local reassignment, mutation counters, and mutable parser state from
  `packages/konyak_cli/lib/src/domain/**`; allow exceptions only when a proven
  performance problem requires one.
- Completed work: removed the remaining domain reassignment hotspots in process
  metadata normalization, PE parsing helpers, pinned program repair,
  winetricks verb parsing, graphics hint byte matching, shortcut parsing, and
  runtime archive planning; added `scripts/verify_domain_reassignment.dart` and
  wired it into governance so `packages/konyak_cli/lib/src/domain/**` fails on
  assignment expressions, `var`, and `++`/`--`.
- Remaining work: none for this slice. Future performance-motivated exceptions
  must be explicit and narrowly justified before adding domain reassignment.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just verify-governance`, `just format-check`, `just verify-safety`,
  `just cli-test`, `just lint`, dedicated
  `scripts/verify_domain_reassignment.dart`, and `git diff --check` passed.

- Timestamp: 2026-06-28 02:58 JST
- State: `completed`
- Branch: `main`
- Active work: prohibit nullable and `null` control/data flow outside direct
  external I/O and payload boundary code.
- Related TODO: none; this is a focused code-quality hardening requested after
  the nullable sentinel cleanup.
- Latest commit: `49ebf43` (`Remove nullable sentinel result flow`).
- Purpose: keep absence and fallible branches represented by `Option`, sealed
  states, or boundary parser results instead of nullable values in internal
  Dart code, while preserving public CLI/Flutter contracts.
- Completed work: added governance coverage that fails on `null`, nullable
  types, and `toNullable`/`fromNullable` outside declared external boundaries;
  converted runtime settings view-model state to a sealed available/unavailable
  model; moved HostEnvironment, ProgramRunEnvironment, runtime component
  lookup, runtime install planning, runtime update checks, runtime validation
  helpers, memory repository lookups, storage path defaults, app update handoff
  selection, launcher environment selection, and selected path/environment
  helpers to `Option`/`match` without local reassignment.
  Removed remaining write-status and parser-counter reassignment from the Linux
  and macOS launcher/file-association helpers touched by this slice.
- Remaining work: none for this slice. External payload parsers, CLI/JSON,
  filesystem/process/platform adapters, Flutter framework adapters, and current
  JSON contract renderers remain the allowed nullable boundary.
- Next action: continue with the product/runtime backlog in `docs/todo.md`.
- Verification: `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just flutter-analyze`, `just verify-governance`, `just format-check`,
  `just cli-test`, `just flutter-test`, `just verify-safety`,
  `just flutter-format-check`, `just lint`, and `git diff --check` passed.

- Timestamp: 2026-06-28 02:14 JST
- State: `completed`
- Branch: `main`
- Active work: remove nullable sentinel control flow from CLI Dart
  Result/Option handling.
- Related TODO: none; this is a focused code-quality refactor requested after
  the domain value-object replacement.
- Latest commit: `52fd55f` (`Replace domain primitives with value objects`).
- Purpose: keep failure, absence, and success branches explicit in
  `Result`/`Either`/`Option`/sealed result code instead of using `null` as an
  intermediate success sentinel.
- Completed work: removed `fold<T?>` nullable intermediates and
  `getOrElse((_) => Option.none())` failure collapsing from repository and CLI
  code; converted private success-null/failure-string helpers for runtime
  downloads, runtime archive installation, AppImage preflight, GPTK/D3DMetal
  validation, registry updates, DLL sync, async process listing, and Flutter
  auto-pin baseline flow to `Either` or private sealed result branches; replaced
  Option/sealed branches that returned `null` with `match`, `switch`, callback,
  or boundary `toNullable()` forms; added governance checks for the sentinel
  patterns; removed the remaining runtime settings view-model reassignment by
  using final values and an IIFE.
- Remaining work: none for the nullable sentinel cleanup. Existing nullable
  parser and UI boundary APIs remain where they are the public/local nullable
  contract rather than Result/Option failure control flow.
- Next action: review and commit the cleanup.
- Verification: `cd packages/konyak_cli && dart analyze --fatal-infos`,
  `just flutter-analyze`, `just cli-test`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just flutter-format-check`,
  `just format-check`, `just lint`, `git diff --check`, and targeted `rg`
  searches for the removed sentinel and reassignment patterns passed.

- Timestamp: 2026-06-28 01:10 JST
- State: `completed`
- Branch: `main`
- Active work: replace semantic CLI domain primitives with domain value objects.
- Related TODO: none; this completes the focused value-object replacement work.
- Latest commit: `532615d` (`Extract program settings form controller`).
- Purpose: move all domain values with meaning or invariants out of raw
  primitives while preserving CLI JSON, persisted metadata, and platform/I/O
  boundary contracts.
- Completed work: changed the remaining bottle mutation, runtime settings,
  program catalog/metadata, program settings, program run, runtime install,
  runtime record, runtime update, app update, process, and environment value
  fields to value objects; kept constructors validating external primitive
  inputs; unwrapped `.value` only at JSON, repository, filesystem, process, and
  platform boundaries; updated immutability and CLI contract tests; updated
  governance checks to lock the new VO fields.
- Remaining work: none for the semantic primitive domain replacement. Plain
  labels/messages and I/O payload strings remain primitive by design.
- Next action: continue product/runtime backlog from `docs/todo.md`.
- Verification: focused failures and full `cli-test` failures were observed
  during the replacement. After implementation, `just cli-test`,
  `just verify-safety`, `just verify-governance`, `just format-check`,
  `just lint`, and `git diff --check` passed.

- Timestamp: 2026-06-27 23:55 JST
- State: `completed`
- Branch: `main`
- Active work: narrow `sealed` usage in the new domain value objects to the
  actual pattern-matching bases.
- Related TODO: none; this refines the focused value-object preparation work.
- Latest commit: `6da4ea3` (`Split home navigation state`).
- Purpose: avoid marking single-case value objects as sealed when they are not
  themselves unions; keep closed hierarchies only where switch-pattern entry
  points are intentional.
- Completed work: converted the individual freezed value object declarations
  from `sealed class` to `abstract class`, leaving `DomainValueObject`,
  `StringDomainValueObject`, `IntDomainValueObject`, and
  `DoubleDomainValueObject` sealed as the closed bases used for pattern
  matching.
- Remaining work: none for sealed-scope cleanup. Existing primitive field
  replacement remains deferred.
- Next action: begin the first compatibility-preserving value-object
  replacement slice after this modeling shape is accepted.
- Verification: `just cli-codegen`, focused domain value object test, CLI
  analyzer, `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-27 23:49 JST
- State: `completed`
- Branch: `main`
- Active work: keep freezed-generated Dart out of git while preserving fresh
  checkout verification for the new domain value objects.
- Related TODO: none; this corrects the code generation policy for the focused
  value-object preparation work.
- Latest commit: `6da4ea3` (`Split home navigation state`).
- Purpose: avoid committing generated freezed output and make repository gates
  responsible for producing generated files before CLI analyze/test/format
  checks need them.
- Completed work: ignored `*.freezed.dart`, removed the generated
  `domain_value_objects.freezed.dart` from the commit set, and added a
  `cli-codegen` just target that runs `dart run build_runner build` before
  `cli-format-check`, `cli-analyze`, and `cli-test`.
- Remaining work: none for generated-file policy. Existing primitive field
  replacement remains deferred.
- Next action: begin the first compatibility-preserving value-object
  replacement slice after this tooling shape is accepted.
- Verification: focused domain value object test, `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed with freezed output generated locally as an ignored file.

- Timestamp: 2026-06-27 23:43 JST
- State: `completed`
- Branch: `main`
- Active work: rebuild the new domain value objects around `freezed`, sealed
  bases, and standalone Dart library boundaries instead of extending the
  existing large `part` graph.
- Related TODO: none; this is the corrected domain modeling preparation before
  replacing existing primitive fields.
- Latest commit: `6da4ea3` (`Split home navigation state`).
- Purpose: keep semantic primitive values as immutable complete-constructor
  value objects while reducing hand-written equality/hash/toString code and
  making the types usable with Dart switch pattern matching.
- Completed work: added `freezed_annotation`, `freezed`, and `build_runner` to
  the CLI package; converted `domain_value_objects.dart` from a `part of`
  source file into a standalone exported domain library; regenerated
  `domain_value_objects.freezed.dart`; modeled value objects as `sealed class`
  freezed types implementing sealed value-object bases; disabled generated
  `copyWith`, `when`, and `map` APIs so invariants cannot be bypassed and Dart
  switch patterns remain the intended matching surface.
- Remaining work: existing records, parser results, JSON contracts, repository
  storage, and Flutter summaries still use primitives. Replace them in small
  slices without changing external CLI output or persisted metadata shape.
- Next action: start replacement at the lowest-risk identity/path slice, likely
  `BottleRecord` and `PinnedProgramRecord`, while keeping serialization stable.
- Verification: failing focused test observed first for the missing sealed
  value-object base. Focused test and analyzer passed after the freezed
  conversion. Full CLI and repository gates passed: `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint`.

- Timestamp: 2026-06-27 23:21 JST
- State: `completed`
- Branch: `main`
- Active work: define domain value objects for semantic primitive values before
  replacing existing primitive fields.
- Related TODO: none; this is a focused domain modeling preparation requested
  before broader replacement work.
- Latest commit: `6da4ea3` (`Split home navigation state`).
- Purpose: make the implicit invariants and meanings behind non-label
  primitive domain values explicit before changing existing model fields,
  parser contracts, repository storage, or Flutter summaries.
- Completed work: reviewed the current primitive-domain audit, added failing
  focused tests first for missing value objects, introduced immutable complete
  constructor value object types under the CLI domain for bottle/program IDs,
  paths, Windows versions, runtime settings finite values, runtime/update
  identities and statuses, graphics backend hint values, environment variable
  names, and bounded numeric settings.
- Remaining work: replace existing primitive fields and parser/result
  contracts with these value objects in small compatibility-preserving slices.
  No existing domain model, CLI JSON, repository storage, or Flutter summary
  usage has been rewired yet.
- Next action: start with the narrowest replacement slice, likely
  `BottleRecord`/`PinnedProgramRecord` identity and path fields, while keeping
  JSON output and persisted bottle metadata stable.
- Verification: failing focused test observed first for undefined value object
  classes with `cd packages/konyak_cli && dart test
  test/domain_value_objects_test.dart`. After implementation, the focused test
  passed. `dart format` ran on the new/changed Dart files. Full CLI and
  repository gates passed: `just cli-test`, `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint`.

- Timestamp: 2026-06-27 22:52 JST
- State: `completed`
- Branch: `main`
- Active work: extract shared program settings form state for Run Program and
  pinned Program Configuration.
- Related TODO: Deferred / Split Flutter large UI files after backend
  boundaries are smaller.
- Latest commit: `6da4ea3` (`Split home navigation state`).
- Purpose: keep `RunProgramDialog` and `ProgramConfigurationView` focused on
  rendering and event wiring by moving duplicated locale, arguments,
  environment, and logging controller state into a shared form controller.
- Completed work: committed the first home navigation split, read the current
  TODO/progress state plus the existing Run Program, Program Configuration,
  program settings, and environment editor code, added failing form-controller
  tests, introduced `ProgramSettingsFormController`, and rewired both
  `RunProgramDialog` and `ProgramConfigurationView` through the shared
  controller for locale, arguments, environment rows, logging, optional
  one-shot settings, and effective log path selection.
- Remaining work: none for this form-controller split. The broader UI split
  TODO remains: continue moving view models and action selection out of the
  remaining large Flutter UI files.
- Next action: continue the UI split with the next small extraction from the
  home/detail/sidebar surface or with runtime settings view-model cleanup in
  bottle configuration.
- Verification: failing focused test observed first for missing
  `ProgramSettingsFormController`. Focused tests passed for the new controller
  unit tests and representative Run Program / pinned Program Configuration
  widget flows. Full Flutter gates passed: `just flutter-format-check`,
  `just flutter-analyze`, and `just flutter-test`. Repository gates passed:
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint`.

- Timestamp: 2026-06-27 22:43 JST
- State: `completed`
- Branch: `main`
- Active work: split Flutter home UI navigation state out of `home_screen.dart`.
- Related TODO: Deferred / Split Flutter large UI files after backend
  boundaries are smaller.
- Purpose: make `KonyakHome` focus on rendering and event wiring by moving
  bottle/program selection and detail-mode transition rules into a small
  testable navigation state helper.
- Completed work: read the current TODO/progress state, reviewed the current
  home, sidebar, bottle detail, bottle list utility, and bottle summary code,
  added failing pure tests for home navigation state, introduced
  `KonyakHomeNavigationState`, and rewired `KonyakHome` to use it for bottle
  selection, bottle configuration navigation, pinned program configuration
  navigation, pending-setting navigation locks, and state reconciliation when
  bottles or pinned programs disappear.
- Remaining work: none for this first home navigation split. The broader UI
  split TODO remains: continue moving view models and action selection out of
  the remaining large Flutter UI files.
- Next action: continue the UI split with the next controller/state extraction,
  likely shared program settings form state between `ProgramConfigurationView`
  and `RunProgramDialog`.
- Verification: failing focused test observed first for missing
  `KonyakHomeNavigationState`. Focused tests passed for the new navigation
  state unit tests and representative existing widget flows for sidebar
  toggling, bottle configuration navigation, and pinned program configuration.
  Full Flutter gates passed: `just flutter-format-check`,
  `just flutter-analyze`, and `just flutter-test`. Repository gates passed:
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint`.

- Timestamp: 2026-06-27 22:21 JST
- State: `completed`
- Branch: `main`
- Active work: commonize one-shot Run Program configuration with pinned program
  configuration.
- Related TODO: none; this is a focused Flutter/CLI program configuration
  refactor.
- Purpose: make the pinned program configuration surface the source of truth for
  program settings controls, add locale to one-shot Run Program options, and
  reduce duplicate settings UI and run execution code paths.
- Completed work: read the current TODO/progress state, added failing Flutter
  coverage for Run Program locale configuration, extracted the pinned program
  settings sections into shared Flutter controls, made Run Program use the same
  program/locale/environment/logging controls, added locale to one-shot Run
  Program settings, widened the Run Program dialog for the shared layout,
  refreshed `apps/konyak/test/goldens/run_program_dialog_options.png`, and
  commonized CLI program settings read/plan/run execution between
  `run-program` and `launch-pinned-program`.
- Remaining work: none for this change.
- Next action: review the diff and commit.
- Verification: failing test observed first for missing Run Program locale
  control. Focused tests passed for the updated Run Program golden, one-shot
  settings CLI arguments, pinned program configuration logging, and CLI
  `run-program`/`launch-pinned-program` settings contracts. Full gates passed:
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, `just lint`, and final `just verify`.

- Timestamp: 2026-06-27 21:52 JST
- State: `completed`
- Branch: `main`
- Active work: add CrossOver-style log file controls to one-shot Run Program
  options and pinned program configuration.
- Related TODO: none; this is a focused CLI/Flutter program execution
  configuration improvement.
- Purpose: expose Konyak's existing program-run log path as user-facing
  configuration, add additional Wine logging channel presets, and keep
  one-shot run and pinned launcher execution on the same stable
  `ProgramSettingsRecord` contract.
- Completed work: added failing CLI and Flutter tests, implemented persisted
  and one-shot program logging settings, applied the settings to run requests,
  `WINEDEBUG`, launcher log creation, and the latest-log UI, added shared
  CrossOver-style Wine logging channel presets, added Run Program and pinned
  Program Configuration controls with localization, updated golden coverage,
  and inspected the generated screenshots.
- Remaining work: none for this change.
- Next action: review the diff and commit.
- Verification: focused CLI contract tests passed, `just cli-test` passed, and
  `just flutter-test` passed. Earlier required gates passed for governance,
  safety, formatting, and lint after fixing one lint finding. Final
  `just verify` passed after the implementation and progress update.

- Timestamp: 2026-06-27 20:37 JST
- State: `completed`
- Branch: `main`
- Active work: investigate why `/Applications/Konyak.app` still prompts to
  install `v1.0.4` after the app update appears to have completed, and release
  the fix as a follow-up patch.
- Related TODO: none; this is a release/update defect investigation.
- Purpose: prove the actual installed app version and update-check behavior
  through the packaged Konyak app/CLI path, then fix the smallest stable
  contract that prevents stale update prompts after successful app updates.
- Completed work: read current TODO/progress state and located the Flutter
  startup update prompt, CLI `check-app-update --json`, app update checker, and
  app update installer code paths. Sub-agent workstream isolation was
  considered for this app-update defect, but the available multi-agent tool is
  restricted to explicit user requests; investigation, implementation, and audit
  notes are being kept in this progress entry and verification output instead.
  Dynamically inspected `/Applications/Konyak.app`: Info.plist and Spotlight
  report `CFBundleShortVersionString=1.0.4` / `CFBundleVersion=5`, but the
  packaged `/Applications/Konyak.app/Contents/Resources/konyak-cli
  check-app-update --json` reported `currentVersion=1.0.3`,
  `latestVersion=v1.0.4`, and `status=available`. Root cause: the Flutter app
  release version was updated from `pubspec.yaml`, but the CLI's
  `konyakAppVersion` constant stayed at `1.0.3`, so the updated app's embedded
  CLI still believed it was older than the latest release. Added failing tests
  first, then made the CLI app version a `KONYAK_APP_VERSION` compile-time
  default, passed the `pubspec.yaml` build name into macOS/Linux release CLI
  compilation, extended release preparation to update and rollback the CLI
  version default with `pubspec.yaml`, and added governance coverage requiring
  the Flutter app version and CLI app update version to match. Committed the fix
  as `b2114c0` (`Fix packaged app update version`), released `v1.0.5` as
  `65fe528` (`Release v1.0.5`), and confirmed the public GitHub Release at
  `https://github.com/serika12345/Konyak/releases/tag/v1.0.5` with macOS DMG,
  Linux AppImage, release metadata, checksums, and runtime stack manifest
  assets. The tag-push release workflow initially hit a release-create race with
  the explicit publish dispatch, then passed after rerunning the failed job
  against the now-existing release.
- Remaining work: none for the stale `v1.0.4` update prompt fix and `v1.0.5`
  release.
- Next action: installed `v1.0.4` apps should update once more to `v1.0.5`; the
  embedded CLI in `v1.0.5` reports `currentVersion=1.0.5`, so the same-version
  prompt should not reappear after that update completes.
- Verification: dynamic failure evidence captured with packaged app probes:
  `plutil -p /Applications/Konyak.app/Contents/Info.plist`, `mdls
  /Applications/Konyak.app`, and
  `/Applications/Konyak.app/Contents/Resources/konyak-cli check-app-update
  --json`. TDD failures observed first with `just release-automation-test` and
  `cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "app
  update checker defaults to the packaged Konyak app version"`. Focused tests
  passed after the fix: `python3 -m py_compile scripts/prepare_release.py
  scripts/prepare_release_test.py scripts/verify_governance.py`, `just
  release-automation-test`, the focused CLI app update checker test, the
  focused macOS release packaging contract test, and the focused Linux release
  packaging contract test. Dynamic fixed-path proof passed by compiling the CLI
  with `dart compile exe -D KONYAK_APP_VERSION=1.0.4 bin/konyak.dart` and
  running `check-app-update --json` against local `v1.0.4` release metadata,
  which returned `currentVersion=1.0.4` and `status=current`. Full repository
  verification passed with `just verify`. Release execution passed with
  `python3 scripts/prepare_release.py --version 1.0.5 --release-notes
  .dart_tool/konyak/release-notes.md --gate "just release-candidate-gates"
  --commit --tag --push --dispatch-publish`; the gate ran `just verify`, built
  `.dart_tool/konyak/release/macos/Konyak-1.0.5-macos-arm64.dmg`, and passed
  macOS packaged runtime extraction, DMG layout, PuTTY Finder integration,
  packaged app CLI bridge, and app update handoff smokes. GitHub Actions run
  `28287713870` completed successfully: `Verify release candidate`, `Linux
  AppImage`, `macOS app`, and `Publish GitHub release` all succeeded. The
  tag-push `Konyak Release` run `28287713615` succeeded after rerun, and main
  push checks `Konyak Verify` (`28287712668`), `Linux Runtime CLI Smoke`
  (`28287712657`), and `macOS Runtime CLI Smoke` (`28287712671`) succeeded.

- Timestamp: 2026-06-27 19:53 JST
- State: `completed`
- Branch: `main`
- Active work: release Konyak `v1.0.4` with checked-in release notes and the
  maintained release gates.
- Related TODO: none; this is a release execution task using the release
  automation documented in `docs/release.md`.
- Purpose: publish the next Konyak release after verifying the repository,
  building release candidates, creating the release commit and annotated tag,
  dispatching the publish workflow, and confirming the GitHub Release.
- Completed work: read the current TODO/progress state, confirmed the latest
  existing release tag was `v1.0.3`, confirmed GitHub CLI authentication, and
  inspected the release automation and publish workflow paths used for
  `v1.0.4`. Sub-agent workstream isolation was considered for the release
  artifact work, but the available multi-agent tool is restricted to explicit
  user requests; investigation, execution, and audit notes were kept in this
  progress entry and verification output instead. Committed the release
  automation prerequisite as `c28aa9b` (`Automate VSCode release flow`). Created
  release notes, ran the maintained release preparation script, updated the app
  version from `1.0.3+4` to `1.0.4+5`, committed `409f9cc` (`Release v1.0.4`),
  created and pushed annotated tag `v1.0.4`, dispatched `publish.yml`, and
  confirmed the public GitHub Release at
  `https://github.com/serika12345/Konyak/releases/tag/v1.0.4`.
- Remaining work: none for `v1.0.4`; only this progress-record commit remains
  to push after the release tag.
- Next action: continue with the next TODO-backed task when requested.
- Verification: preflight and focused checks passed before the automation
  prerequisite commit: `python3 -m py_compile scripts/prepare_release.py
  scripts/prepare_release_test.py`, `just release-automation-test`, JSON parsing
  for `.vscode/tasks.json`, Ruby YAML parsing for
  `.github/workflows/prepare-release.yml` and `.github/workflows/publish.yml`,
  `zsh -n scripts/draft_release_notes.zsh
  scripts/run_release_candidate_gates.zsh`, `just verify-governance`, and
  `git diff --cached --check`. Release execution passed with
  `python3 scripts/prepare_release.py --version 1.0.4 --release-notes
  .dart_tool/konyak/release-notes.md --gate "just release-candidate-gates"
  --commit --tag --push --dispatch-publish`; the gate ran `just verify`, built
  `.dart_tool/konyak/release/macos/Konyak-1.0.4-macos-arm64.dmg`, and passed
  macOS packaged runtime extraction, DMG layout, PuTTY Finder integration,
  packaged app CLI bridge, and app update handoff smokes. GitHub Actions run
  `28286961564` completed successfully: `Verify release candidate`, `Linux
  AppImage`, `macOS app`, and `Publish GitHub release` all succeeded. GitHub
  Release verification confirmed tag `v1.0.4`, published/non-draft/non-prerelease
  status, release-note body with SHA-256 checksums, and 10 release assets:
  macOS DMG/checksum/metadata, Linux AppImage/checksum/metadata, combined
  `SHA256SUMS`, Linux runtime stack source manifest, manifest signature, and
  runtime stack public key.

- Timestamp: 2026-06-27 19:35 JST
- State: `completed`
- Branch: `main`
- Active work: add a VSCode-driven app release flow with version input,
  editable release notes, local build gates, and publish dispatch.
- Related TODO: none; this extends the release-preparation automation in
  `docs/release.md`.
- Purpose: let a release be driven from VSCode by drafting notes, selecting an
  app version, running maintained gates/build checks, and only publishing after
  the maintained release workflow succeeds.
- Completed work: read current TODO/progress state, `.vscode/tasks.json`,
  release documentation, `prepare_release.py`, release build scripts,
  `publish.yml`, and governance checks. Sub-agent workstream isolation was
  considered, but the available multi-agent tool is restricted to explicit user
  requests; investigation, implementation, and audit notes are being kept in
  this progress entry and verification output instead. Added release notes
  handoff support to `scripts/prepare_release.py`, copying draft Markdown into
  `docs/releases/v<version>.md`; added rollback coverage for invalid notes and
  failed gates; added `scripts/draft_release_notes.zsh`,
  `scripts/run_release_candidate_gates.zsh`, `just draft-release-notes`,
  `just release-candidate-gates`, VSCode tasks for drafting notes and releasing
  from draft notes, publish workflow release-note ingestion from the tag ref, an
  optional `release_notes` input to the prepare workflow, release documentation,
  VSCode documentation, and governance sentinels.
- Remaining work: none for the VSCode-driven parent-repository release flow.
- Next action: review the diff and commit. For the next release, run
  `Konyak: Draft Release Notes`, edit `.dart_tool/konyak/release-notes.md`, then
  run `Konyak: Release From Draft Notes` from a clean branch.
- Verification: TDD failure observed first with `just release-automation-test`
  before `--release-notes` existed. Focused and static checks passed:
  `python3 -m py_compile scripts/prepare_release.py
  scripts/prepare_release_test.py`, `just release-automation-test`, JSON parsing
  for `.vscode/tasks.json`, Ruby YAML parsing for
  `.github/workflows/prepare-release.yml` and `.github/workflows/publish.yml`,
  `zsh -n scripts/draft_release_notes.zsh
  scripts/run_release_candidate_gates.zsh`, `just verify-governance`,
  `just --list`, and `git diff --check`. Smoke-tested
  `scripts/draft_release_notes.zsh` with
  `KONYAK_RELEASE_NOTES_DRAFT=.dart_tool/konyak/release-notes-smoke.md`. Dynamic
  release gate verification passed with `just release-candidate-gates`: it ran
  `just verify`, built `.dart_tool/konyak/release/macos/Konyak-1.0.3-macos-arm64.dmg`,
  and passed macOS packaged runtime extraction, DMG layout, PuTTY Finder,
  packaged app CLI bridge, and app update handoff smokes.

- Timestamp: 2026-06-27 19:20 JST
- State: `completed`
- Branch: `main`
- Active work: automate Konyak release version updates, release readiness
  decision gates, tag creation, and publish workflow dispatch.
- Related TODO: none; this tightens the existing release workflow documented in
  `docs/release.md`.
- Purpose: replace manual app-version edits and tag creation with a maintained
  release-preparation path that runs release gates before publishing can start.
- Completed work: read the current TODO/progress state, existing release
  documentation, release build scripts, `just` verification targets, and
  GitHub release workflow. Sub-agent workstream isolation was considered for
  this release-process change, but the available multi-agent tool is restricted
  to explicit user requests; investigation, implementation, and audit notes are
  being kept in this progress entry and verification output instead. Added
  `scripts/prepare_release.py`, a focused release automation test, a
  `just prepare-release` entry point, the manual `Prepare Konyak Release`
  workflow, release documentation, and governance sentinels for the workflow,
  docs, and script. The preparation path updates `apps/konyak/pubspec.yaml`,
  runs release gates before commit/tag, rolls the pubspec back when a gate
  fails, commits `Release v<version>`, creates the annotated `v<version>` tag,
  can push the commit/tag, and can dispatch `publish.yml` on the tag ref.
- Remaining work: none for parent-repository release-preparation automation.
- Next action: review the diff and commit; use the `Prepare Konyak Release`
  workflow or `just prepare-release` from a clean branch for the next release.
- Verification: TDD failure observed first with `just release-automation-test`
  before `scripts/prepare_release.py` existed. Focused and static checks passed:
  `python3 -m py_compile scripts/prepare_release.py
  scripts/prepare_release_test.py`, `just release-automation-test`, Ruby YAML
  parsing for `.github/workflows/prepare-release.yml` and
  `.github/workflows/publish.yml`, and `git diff --check`. Required gates
  passed: `just verify-governance`, `just verify-safety`, `just format-check`,
  `just lint`, `just test`, and the integrated `just verify`.

- Timestamp: 2026-06-27 18:53 JST
- State: `completed`
- Branch: `main`
- Active work: add static graphics backend selection hints for Windows
  programs.
- Related TODO: none; this is a focused UX/CLI contract improvement for
  choosing existing graphics backends.
- Purpose: inspect a selected Windows program without running it and surface
  candidate graphics backend hints through the existing CLI-to-Flutter
  boundary.
- Completed work: read current TODO/progress state, Flutter architecture notes,
  the run program dialog, CLI program command handling, PE metadata parsing,
  runtime settings models, and bottle graphics settings controls; added
  `suggest-graphics-backend --program <path> --json`; extended PE parsing with
  import DLL names; added static graphics signal analysis for D3D9, D3D10/11,
  D3D12, OpenGL, and Vulkan hints; added Flutter CLI parsing and a run dialog
  hint button/result panel; added English/Japanese localization entries; added
  CLI, client, widget, localization, and golden coverage.
- Remaining work: none for the static hint path.
- Next action: review the uncommitted diff and commit when ready.
- Verification: focused tests passed:
  `cd packages/konyak_cli && dart test test/cli_contract_test.dart --name
  "suggest-graphics-backend"`, `cd apps/konyak && flutter test
  test/cli/konyak_cli_client_test.dart --plain-name "loads graphics backend
  hints through the JSON CLI contract"`, `cd apps/konyak && flutter test
  test/widget_test.dart --plain-name "run program dialog displays graphics
  backend hints"`, `cd apps/konyak && flutter test test/widget_test.dart
  --plain-name "run program dialog requests graphics backend hints from the
  CLI"`, and `cd apps/konyak && flutter test
  test/app/localization_resources_test.dart`. Generated and rechecked golden
  artifact:
  `apps/konyak/test/goldens/run_program_dialog_graphics_hint.png`.
  Required gates passed: `just verify-governance`, `just verify-safety`,
  `just format-check`, `just lint`, `just flutter-format-check`, `just
  flutter-analyze`, `just flutter-test`, and `just cli-test`. `git diff
  --check` passed.

- Timestamp: 2026-06-27 14:58 JST
- State: `completed`
- Branch: `codex/visible-graphics-smoke`
- Active work: require macOS runtime CI and local graphics checks to use
  minimal samples that create visible windows and clear/present through the
  selected backend.
- Related TODO: end-to-end DLSS/MetalFX rendering proof; this tightens the
  prerequisite graphics smoke contract so backend validation is based on
  visible rendering samples rather than device-only probes.
- Purpose: replace D3D11/D3D12 backend device-only smoke execution with
  Konyak-owned visible graphics samples run through the public CLI path.
- Completed work: read the current TODO/progress state; inspected the existing
  macOS runtime CLI smoke script, D3D11 visible probe, D3D11/D3D12 device
  probes, and workflow triggers; updated repository contract tests so the
  parent macOS runtime smoke rejects device-only probes and expects visible
  graphics samples; added a sentinel file to the visible D3D11 sample after its
  clear/present loop; changed the parent runtime CLI smoke script to build and
  run visible D3D11 samples for DXVK-macOS and DXMT; changed the D3D12 MSVC
  smoke to run as a visible sample, selecting D3DMetal automatically when the
  local runtime has the user-imported GPTK/D3DMetal component and otherwise
  falling back to the non-GPTK D3D12 backend so parent CI does not download or
  overlay proprietary GPTK payloads; updated workflow path triggers to watch
  visible sample sources instead of runtime-submodule device probes.
- Remaining work: none for the parent repository visible-sample smoke path.
  Runtime-submodule direct Wine backend probe jobs remain separate low-level
  diagnostics and were not changed in this parent-repository task.
- Next action: push `codex/visible-graphics-smoke` and run GitHub Actions
  workflow dispatch for CI confirmation.
- Verification: focused tests passed:
  `flutter test test/macos_window_metrics_test.dart --plain-name "macOS runtime
  CLI smoke runs visible graphics samples through the CLI"` and `flutter test
  test/windows_d3d12_fixture_test.dart --plain-name "Windows D3D12 MSVC fixture
  has pinned build entrypoints"`. Static checks passed: `scripts/build_d3d11_probe_exe.zsh`,
  `zsh -n scripts/run_macos_runtime_cli_smoke.zsh`, Ruby YAML parsing for
  `.github/workflows/macos-runtime-cli-smoke.yml`, and `git diff --check`.
  Dynamic local smoke passed through the public CLI path with
  `KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL=false`,
  `KONYAK_MACOS_RUNTIME_CLI_SMOKE_WORK_ROOT=.dart_tool/konyak/macos-runtime-visible-smoke-final`,
  and the Windows-runner-built D3D12 executable at
  `.dart_tool/konyak/windows-d3d12-fixture-local-display/konyak_d3d12_minimal.exe`;
  it ran DXVK and DXMT D3D11 visible samples, selected `d3dmetal` for the
  D3D12 visible sample on the local GPTK/D3DMetal-capable runtime, wrote
  `KONYAK_D3D11_PROBE_OK` sentinels for both D3D11 bottles and
  `KONYAK_D3D12_MINIMAL_SAMPLE_OK` for the D3D12 bottle, and printed
  `macOS runtime CLI smoke passed.` Required gates passed: `just
  verify-governance`, `just verify-safety`, `just format-check`, `just lint`,
  and `just flutter-test`. Sub-agent workstream isolation was used: explorer
  agent `019f0797-dc57-7e52-84ca-b871d343f545` audited the current probe/sample
  contracts, confirmed the parent change set as the smallest safe scope, and
  identified runtime-submodule direct Wine diagnostics as separate follow-up
  work if product policy later requires those jobs to stop using device-only
  probes.

- Timestamp: 2026-06-27 13:53 JST
- State: `completed`
- Branch: `codex/d3d12-msvc-fixture`
- Active work: connecting the MSVC/CMake-built D3D12 Windows smoke fixture to
  CI runtime execution.
- Related TODO: end-to-end DLSS/MetalFX rendering proof; this is prerequisite
  probe infrastructure for proving D3D12 runtime behavior through Konyak-owned
  execution paths.
- Purpose: build the small Windows D3D12 executable on GitHub's Windows runner
  and feed the resulting artifact into Konyak runtime smoke execution through
  the public CLI path.
- Completed work: built the fixture successfully in GitHub Actions on branch
  `codex/d3d12-msvc-fixture`; reviewed runtime smoke script and workflow entry
  points; added a failing repository test for the CI artifact handoff; updated
  the macOS runtime smoke workflow to build the Windows D3D12 fixture, upload
  it as `konyak-d3d12-minimal-sample-windows-x64`, download it on the macOS
  smoke job, and pass it to `scripts/run_macos_runtime_cli_smoke.zsh`; updated
  the smoke script to create a `d3d12-msvc-sample` bottle, select the vkd3d
  backend settings, run the executable through `run-program --json`, and wait
  for a `C:\konyak-d3d12-minimal-sample-ok.txt` sentinel file containing
  `KONYAK_D3D12_MINIMAL_SAMPLE_OK`. The first macOS smoke dispatch on commit
  `10dea8d` reached `run-program d3d12-msvc-sample` but failed because the
  macOS Wine runner launches through `wineloader start /unix`, which returns
  before the child process stdout is captured in `latest.log`; the sample now
  mirrors the existing backend probe sentinel contract instead of relying on
  Wine `start` stdout. Sub-agent workstream isolation is not available for this
  task because the multi-agent tool can only spawn agents after an explicit
  user request; investigation, implementation, and audit notes are kept in this
  progress entry and verification logs instead.
- Remaining work: none for connecting the D3D12 fixture to CI runtime smoke.
- Next action: open the branch as a PR when repository permissions allow it.
- Verification: local checks passed:
  `flutter test test/windows_d3d12_fixture_test.dart --plain-name "Windows D3D12
  MSVC fixture has pinned build entrypoints"`; `zsh -n
  scripts/run_macos_runtime_cli_smoke.zsh`; Ruby YAML parsing for
  `.github/workflows/macos-runtime-cli-smoke.yml` and
  `.github/workflows/windows-d3d12-fixture-build.yml`; `git diff --check`;
  `just verify-governance`; `just verify-safety`; `just format-check`;
  `just lint`; `just flutter-test`. GitHub Actions on commit `10dea8d`:
  `Konyak Verify` run `28278439596` passed; `Windows D3D12 Fixture Build` run
  `28278439582` passed; `macOS Runtime CLI Smoke` run `28278442192` built and
  downloaded the D3D12 artifact, passed the existing backend probes, reached the
  D3D12 sample through `run-program`, then failed only because `latest.log`
  lacked stdout marker capture from Wine `start /unix`. GitHub Actions on
  commit `5552dd6`: `Konyak Verify` run `28278817790` passed; `Windows D3D12
  Fixture Build` run `28278817802` passed after the sentinel addition; `macOS
  Runtime CLI Smoke` run `28278820001` passed, with the workflow's Windows job
  building/uploading `konyak_d3d12_minimal.exe`, the macOS job downloading that
  artifact, running `konyak run-program d3d12-msvc-sample ... --json` with
  `{"arguments":"--frames 2","environment":{}}`, observing the sentinel, and
  printing `macOS runtime CLI smoke passed.`
