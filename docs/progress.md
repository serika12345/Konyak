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

- Timestamp: 2026-06-30 12:59 JST
- State: `completed`
- Branch: `main`
- Active work: Replace program window probe nullable results.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Replace program window probe nullable results`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  result state by replacing program-window probe `Set?` returns with explicit
  available/unavailable variants.
- Completed work: added a failing unavailable-probe contract test; added
  Freezed `ProgramWindowProbeResult<T>` with immutable `available` and
  `unavailable` variants; updated native and test probes to return explicit
  variants; replaced `home_loader_programs.dart` launch-tracking `Set?`
  branches with switch-based result handling.
- Remaining work: none for this batch.
- Next action: continue narrowing `home_loader_programs.dart` nullable state,
  especially dialog cancellation and optional one-shot run settings, while
  keeping UI/framework nullability separate from domain result variants.
- Verification: observed
  `flutter test test/app/program_window_probe_test.dart` fail before
  implementation because `ProgramWindowProbeResult` did not exist. After
  implementation, targeted `flutter test test/app/program_window_probe_test.dart`
  and selected launch-progress widget tests passed. `just flutter-format-check`,
  `just flutter-analyze`, and `just flutter-test` passed in the Nix dev shell.

- Timestamp: 2026-06-30 12:50 JST
- State: `completed`
- Branch: `main`
- Active work: Replace home-loader JSON error nullable helper.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Replace home-loader JSON error helper`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  helpers by deleting the duplicate `String? jsonErrorMessage` platform helper
  and routing failure message construction through the existing explicit CLI
  JSON error parse result.
- Completed work: added a failing empty-message parser test; added focused
  home-loader platform failure message tests; tightened app CLI JSON error
  parsing so empty messages are explicit absence; replaced the local nullable
  `String? jsonErrorMessage` helper in `home_loader_platform_helpers.dart` with
  the existing `commandFailureMessage` / `JsonErrorMessageParseResult` path.
- Remaining work: none for this batch.
- Next action: continue narrowing `home_loader/` nullable result state, with
  `home_loader_programs.dart` run-setting/probe outcomes as the next likely
  target after separating expected absence from UI/framework nullable values.
- Verification: observed
  `flutter test test/cli/konyak_cli_failure_messages_test.dart
  test/home_loader/home_loader_platform_helpers_test.dart` fail before
  implementation because empty JSON error messages parsed as
  `ParsedJsonErrorMessage`. After implementation, the same targeted test
  command passed. `just flutter-format-check`, `just flutter-analyze`, and
  `just flutter-test` passed in the Nix dev shell.

- Timestamp: 2026-06-30 12:06 JST
- State: `completed`
- Branch: `main`
- Active work: Replace executable auto-run nullable bottle selection.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit
  (`Replace executable auto-run nullable selection`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  result helpers by replacing the executable-open auto-run bottle nullable
  lookup with explicit selection variants.
- Completed work: added a focused executable auto-run selection test; added
  Freezed `ExecutableAutoRunBottleSelection`; replaced
  `executableOpenAutoRunBottle()` nullable returns with explicit `found`,
  `missing`, and `disabled` variants; updated `showOpenExecutable` to switch on
  those variants; regenerated ignored Freezed parts; added a mounted guard
  before opening the executable dialog after the auto-run branch.
- Remaining work: none for this batch.
- Next action: continue narrowing remaining `home_loader/` nullable adapter
  boundaries, starting with the JSON/platform helper null sentinels only after
  separating UI/framework nullable state from app-domain result state.
- Verification: observed
  `flutter test test/home_loader/executable_auto_run_bottle_selection_test.dart`
  fail before implementation because the selection model did not exist. After
  implementation, targeted
  `flutter test test/home_loader/executable_auto_run_bottle_selection_test.dart`
  passed. `just flutter-analyze` initially reported a
  `use_build_context_synchronously` path after the switch conversion; after
  adding the mounted guard, `just flutter-format-check`,
  `just flutter-analyze`, and `just flutter-test` passed in the Nix dev shell.

- Timestamp: 2026-06-30 11:51 JST
- State: `completed`
- Branch: `main`
- Active work: Replace Flutter bottle-loader nullable outcomes.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Replace bottle-loader nullable outcomes`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  async result methods by replacing create/reload bottle nullable returns with
  explicit Freezed outcome variants.
- Completed work: added `BottleOperationOutcome` as a Freezed result variant;
  replaced nullable returns from `createBottleFromDialog`,
  `createBottleFromInput`, and `reloadBottle`; updated executable-open bottle
  creation to switch on explicit outcomes; regenerated ignored Freezed parts.
- Remaining work: none for this batch.
- Next action: continue narrowing `home_loader/` nullable async boundaries,
  then split remaining UI/framework nullable state from loader result state
  before trying to make whole home-loader files strict nullable paths.
- Verification: observed
  `flutter test test/home_loader/bottle_operation_outcome_test.dart` fail
  before implementation because `BottleOperationOutcome` did not exist. After
  implementation, targeted
  `flutter test test/home_loader/bottle_operation_outcome_test.dart`,
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-30 11:36 JST
- State: `completed`
- Branch: `main`
- Active work: Replace Flutter settings-save nullable outcome.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Replace settings-save nullable outcome`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  async result methods by replacing settings-save nullable callback results
  with explicit Freezed outcome variants.
- Completed work: added `AppSettingsSaveOutcome` as a Freezed result variant;
  replaced the settings dialog `Future<AppSettingsSummary?>` callback with an
  explicit save outcome; updated `home_loader_settings.dart` to return
  `saved`, `failed`, or `unmounted`; regenerated ignored Freezed parts.
- Remaining work: none for this batch.
- Next action: continue narrowing `home_loader_bottles.dart` nullable async
  result helpers, especially create/reload bottle outcomes.
- Verification: observed
  `flutter test test/app/app_settings_save_outcome_test.dart` fail before
  implementation because `AppSettingsSaveOutcome` did not exist. After
  implementation, targeted
  `flutter test test/app/app_settings_save_outcome_test.dart`,
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell. `just flutter-analyze` initially
  failed once on a non-const test constructor and passed after making the test
  value const.

- Timestamp: 2026-06-30 11:17 JST
- State: `completed`
- Branch: `main`
- Active work: Replace Flutter runtime-loader nullable async outcomes.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Replace runtime-loader nullable outcomes`).
- Purpose: continue narrowing `apps/konyak/lib/src/home_loader/` nullable
  allowance by replacing runtime-loader nullable async return values with
  explicit Freezed outcome variants.
- Completed work: added a focused immutable snapshot test for runtime-load
  outcomes; replaced nullable returns from `loadKnownRuntimes`,
  `ensureRuntimeForPlatformLoaded`, and `confirmAndInstallManagedRuntime` with
  explicit Freezed outcomes; preserved lifecycle cancellation as `unmounted` or
  `cancelled` variants; regenerated ignored Freezed parts.
- Remaining work: none for this batch.
- Next action: continue narrowing `home_loader/` nullable async result methods,
  especially bottle/settings loader helpers, before trying to make whole files
  strict nullable paths.
- Verification: observed
  `flutter test test/home_loader/known_runtimes_state_test.dart` fail before
  implementation because `KnownRuntimesLoadOutcome` did not exist. After
  implementation, targeted
  `flutter test test/home_loader/known_runtimes_state_test.dart`,
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-30 11:04 JST
- State: `completed`
- Branch: `main`
- Active work: Add Flutter Freezed unions for app state variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Use Freezed for Flutter app unions`).
- Purpose: align Flutter app-side explicit union/value-state modeling with
  the repository Freezed policy now that adding Flutter Freezed dependencies is
  approved.
- Completed work: added Flutter Freezed dependencies and a `flutter-codegen`
  gate; converted app/home-loader/log-reader hand-written state unions to
  Freezed while keeping collection snapshot factories for mutable inputs;
  updated architecture tests so only generated Freezed part files are allowed;
  regenerated ignored `.freezed.dart` outputs.
- Remaining work: none for this batch.
- Next action: continue tightening broader Flutter CLI adapter result types and
  remaining nullable adapter seams when a dedicated compatibility-safe batch is
  available.
- Verification: initial `dart run build_runner build` exposed the wrong SDK
  path for Flutter codegen, so the gate was changed to `flutter pub run
  build_runner build`; initial `just flutter-test` exposed the old `part`
  prohibition and a missing immutable snapshot copy, both fixed. Final
  `flutter pub run build_runner build`, `just flutter-format-check`,
  `just flutter-analyze`, `just flutter-test`, `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint` passed in the
  Nix dev shell.

- Timestamp: 2026-06-30 10:37 JST
- State: `completed`
- Branch: `main`
- Active work: Narrow Flutter home navigation nullable state.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Narrow Flutter navigation state boundary`).
- Purpose: continue tightening broad Flutter `app/` nullable allowances by
  moving home navigation selection state from nullable IDs to explicit
  selection and resolution variants.
- Completed work: updated navigation-state tests to assert explicit selected
  bottle/program state and resolution variants; replaced nullable selected
  bottle/program fields with `HomeNavigation*Selection` values; moved bottle
  and program lookup results to `HomeNavigation*Resolution` variants; kept the
  nullable UI adapter conversion in `home_screen.dart`; removed
  `home_navigation_state.dart` from the broad Flutter `app/`
  nullable-boundary allowance.
- Remaining work: none for this batch.
- Next action: continue tightening broader Flutter app/home-loader nullable
  helpers, especially async loader result methods under `home_loader/`.
- Verification: observed `flutter test test/app/home_navigation_state_test.dart`
  fail before implementation because the explicit selected bottle/program and
  resolution variants did not exist; after implementation, targeted
  `flutter test test/app/home_navigation_state_test.dart`,
  `just konyak-lints-test`, `just flutter-custom-lint`,
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-30 10:27 JST
- State: `completed`
- Branch: `main`
- Active work: Narrow Flutter bottle selection nullable boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Narrow Flutter bottle selection nullable boundary`).
- Purpose: continue tightening broad Flutter `app/` nullable allowances by
  moving pure bottle/program selection helpers from nullable finder returns to
  explicit app selection variants.
- Completed work: added focused selection tests; replaced
  `findSelectedBottle` and `findSelectedProgram` nullable helpers with
  `BottleSelection` and `PinnedProgramSelection` sealed variants; updated home
  navigation reconciliation and home-loader bottle fallback call sites; removed
  `bottle_lists.dart` from the broad Flutter `app/` nullable-boundary
  allowance.
- Remaining work: none for this batch.
- Next action: continue tightening broader Flutter app/home-loader nullable
  helpers, especially async loader results and the remaining navigation state
  nullable fields.
- Verification: observed `flutter test test/app/bottle_lists_test.dart` fail
  before implementation because `findBottleById`,
  `findPinnedProgramByPath`, and their selection variants did not exist; after
  implementation, targeted `flutter test test/app/bottle_lists_test.dart`,
  targeted `flutter test test/app/home_navigation_state_test.dart`,
  `just flutter-custom-lint`, `just konyak-lints-test`,
  `just flutter-format-check`, `just flutter-analyze`, `just flutter-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-30 10:17 JST
- State: `completed`
- Branch: `main`
- Active work: Narrow Flutter runtime platform nullable boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Narrow Flutter runtime nullable boundary`).
- Purpose: continue tightening the broad Flutter `app/` nullable allowance by
  making the pure runtime-platform helper represent missing runtimes with an
  explicit app result variant instead of nullable helper returns.
- Completed work: added focused runtime-platform tests for explicit
  found/missing selection and immutable upsert behavior; replaced nullable
  runtime lookup helpers with sealed `RuntimeForPlatformSelection` variants;
  updated home-loader and startup update call sites to bridge missing runtimes
  only at UI/state boundaries; removed `runtime_platform.dart` from the broad
  Flutter `app/` nullable-boundary allowance.
- Remaining work: none for this batch.
- Next action: continue tightening broader Flutter app/home-loader nullable
  helpers, especially selected bottle/program state and async loader results.
- Verification: observed `flutter test test/app/runtime_platform_test.dart`
  fail before implementation because `runtimeForPlatformSelection` and the
  selection variants did not exist; after implementation, targeted
  `flutter test test/app/runtime_platform_test.dart`, `just flutter-custom-lint`,
  `just konyak-lints-test`, `just flutter-format-check`,
  `just flutter-analyze`, `just flutter-test`, `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint` passed in the
  Nix dev shell. A mistaken `dart format docs/progress.md` attempt failed
  because Markdown is not Dart input and made no Markdown edit.

- Timestamp: 2026-06-30 10:04 JST
- State: `completed`
- Branch: `main`
- Active work: Strengthen functional-domain custom lint enforcement.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `52c413a` (`Tighten IO absence handling`).
- Purpose: close the enforcement gaps found in the nullable/functional audit by
  rejecting domain loop statements, mutable local collection builders, broader
  Result/Either failure-to-`Option.none()` collapse, and nullable
  `BottleRecord` runtime-settings construction.
- Completed work: added failing lint fixtures for domain loop statements,
  mutable local collection builders, and `fold` failure collapse; implemented
  the new custom lint rules; refactored current domain loop/builder call sites
  to expression/fold/Option helpers; changed `BottleRecord` construction to use
  `Option<BottleRuntimeSettings>` for optional runtime settings and removed
  `bottle_models.dart` from the nullable-boundary allowlist.
- Remaining work: none for this lint-hardening batch.
- Next action: continue tightening the broader nullable boundary allowlists,
  especially Flutter app/home-loader state helpers and remaining CLI/io/platform
  parser boundaries.
- Verification: observed `just konyak-lints-test` fail before implementation
  because `konyak_no_domain_loop_statement` was not reported; after rule
  implementation the lint fixture test passed. Observed `just cli-custom-lint`
  fail on existing domain loop/mutable-builder call sites, then pass after the
  expression/fold refactor. Final verification passed with
  `just konyak-lints-test`, `just cli-test`, `just verify-governance`, `just
  verify-safety`, `just format-check`, and `just lint` in the Nix dev shell.

- Timestamp: 2026-06-29 23:51 JST
- State: `completed`
- Branch: `main`
- Active work: Add custom lint guard for nullable absence-result drift.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `52c413a` (`Tighten IO absence handling`).
- Purpose: prevent the recently removed `Option<T>?`, `Future<T?>`, and
  nullable async-cache shapes from returning in the CLI backend while the
  broader JSON/user-input/direct-external nullable boundary is tightened
  incrementally.
- Completed work: added `konyak_no_nullable_absence_result` to reject
  nullable `Option` results, nullable `Future`/`FutureOr` values, and
  `Future`/`FutureOr` payloads whose outer result type is nullable in the CLI
  backend; enabled the rule in real and fixture analysis options; added
  invalid fixture coverage for `Option<T>?`, `Future<T?>`,
  `Future<Map<..., Object?>?>`, and `Future<Option<T>>?`; kept
  `Future<Option<Map<String, Object?>>>` valid for JSON payload handling.
- Remaining work: broader nullable permissions in `cli`/`io`/`platform` are
  still intentionally path-based and should be narrowed by replacing existing
  nullable parser/helper contracts with typed results before removing those
  directory-level allowances.
- Next action: continue tightening nullable/null allowances that are broader
  than JSON, user input, or direct framework/external API boundaries.
- Verification: observed `dart test test/konyak_lints_test.dart` fail before
  implementation because `konyak_no_nullable_absence_result` was not reported;
  after implementation, `just konyak-lints-test`, tools analyzer,
  `just cli-custom-lint`, `just flutter-custom-lint`, `just
  verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 23:18 JST
- State: `completed`
- Branch: `main`
- Active work: Replace remaining I/O double-absence nullable shapes.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `2ab87ee` (`Ban toNullable bridge usage`).
- Purpose: continue the same cleanup after the Wine process metadata cache
  fix by removing `Option<T>?` and non-boundary `Future<String?>` result
  shapes from I/O helpers.
- Completed work: replaced `programLoggingSettingsRecordFromJson`'s
  `Option<ProgramLoggingSettingsRecord>?` with a private sealed parse result;
  changed `DartIoHostProcessSnapshotReader.readPsSnapshot` from
  `Future<String?>` to `Future<Option<String>>`; changed PE icon extraction and
  write helpers from `String?`/`Future<String?>` to `Option<String>`/
  `Future<Option<String>>`; updated metadata projection call sites.
- Remaining work: none for these I/O double-absence candidates.
- Next action: continue tightening nullable/null allowances that are still
  broader than JSON, user input, or direct framework/external API boundaries.
- Verification: focused `list-wine-processes` and `metadata` CLI contract
  tests, `just cli-analyze`, `just cli-test`, `just verify-governance`, `just
  verify-safety`, `just format-check`, and `just lint` passed in the Nix dev
  shell.

- Timestamp: 2026-06-29 23:05 JST
- State: `completed`
- Branch: `main`
- Active work: Replace nullable async Wine process metadata caches.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `2ab87ee` (`Ban toNullable bridge usage`).
- Purpose: remove the confusing `Future<String?>?`/`Future<Map<...>?>?`
  double-nullable cache shape from Wine process metadata resolution.
- Completed work: replaced `Future<String?>? latestLogContents` and
  `Future<Map<String, Object?>?>? launchIndex` with lazy
  `Future<Option<...>>` caches in `AsyncWineProcessHostPathResolver`; changed
  the async file readers to return `Option.none()` for missing, invalid, or
  unreadable cache files.
- Remaining work: none for this async cache cleanup.
- Next action: continue tightening nullable/null allowances that are still
  broader than JSON, user input, or direct framework/external API boundaries.
- Verification: focused `list-wine-processes` CLI contract tests,
  `just cli-analyze`, `just cli-test`, `just verify-governance`, `just
  verify-safety`, `just format-check`, and `just lint` passed in the Nix dev
  shell.

- Timestamp: 2026-06-29 22:54 JST
- State: `completed`
- Branch: `main`
- Active work: Replace nested Option parsing with Do notation.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `ddf9a15` (`Restrict Flutter CLI nullable boundaries`).
- Purpose: keep the all-source `toNullable()` ban readable by replacing the
  heavily nested `Option.flatMap` parsing in repository storage with fpdart Do
  notation.
- Completed work: confirmed fpdart 1.2.0 exposes `Option.Do`; replaced the
  deeply nested runtime-settings `Option.flatMap` chain in
  `repository_storage_io.dart` with `Option.Do`; also converted the
  runtime-settings plus pinned-program parse join in `bottleRecordFromJson` to
  `Option.Do` while preserving `ArgumentError` handling.
- Remaining work: none for this Do notation cleanup.
- Next action: continue tightening nullable/null allowances that are still
  broader than JSON, user input, or direct framework/external API boundaries.
- Verification: `just cli-analyze`, `just cli-test`, `just
  verify-governance`, `just verify-safety`, `just format-check`, and `just
  lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 22:47 JST
- State: `completed`
- Branch: `main`
- Active work: Ban `toNullable()` across Konyak source and remove all uses.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `ddf9a15` (`Restrict Flutter CLI nullable boundaries`).
- Purpose: enforce that `Option` absence is handled explicitly with
  `match`/`map`/`flatMap` rather than bridged back to nullable control flow or
  nullable adapter values.
- Completed work: added a failing custom-lint fixture showing that
  `toNullable()` inside an I/O boundary was not reported; added
  `konyak_no_to_nullable` across Konyak CLI and Flutter sources; kept the
  existing nullable bridge rule focused on `fromNullable()` outside external
  boundaries; replaced all current CLI source `toNullable()` calls with
  explicit `Option.match`/`map`/`flatMap` handling.
- Remaining work: none for the all-source `toNullable()` ban.
- Next action: continue tightening nullable/null allowances that are still
  broader than JSON, user input, or direct framework/external API boundaries.
- Verification: observed `dart test test/konyak_lints_test.dart` fail in the
  Nix dev shell because `lib/src/io/to_nullable_boundary_violation.dart` was
  not reported yet; after implementation, `just cli-custom-lint`, `just
  flutter-custom-lint`, `just konyak-lints-test`, `just cli-analyze`, `just
  cli-test`, `just verify-governance`, `just verify-safety`, `just
  format-check`, and `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 22:31 JST
- State: `completed`
- Branch: `main`
- Active work: Remove Option-to-null control flow from macOS runtime
  validation.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `ddf9a15` (`Restrict Flutter CLI nullable boundaries`).
- Purpose: correct `Option` values that were immediately converted to nullable
  values and checked with `null`, starting with
  `macos_runtime_validator.dart`.
- Completed work: replaced runtime layout path extraction with Option
  `flatMap`/`map` composition and moved missing-layout handling to the Option
  `match` none branch; changed runtime stack completeness checks to use
  `Option.match` instead of `toNullable()` plus `null`.
- Remaining work: audit the wider CLI backend for the same
  `toNullable()`-then-null-branch pattern and replace those with explicit
  Option folds/results where they are not direct serialization or external API
  adapters.
- Next action: continue the broader CLI backend audit, starting with
  runtime-install and repository-storage I/O paths that still bridge Option to
  nullable control flow.
- Verification: focused runtime validator tests passed with `dart test
  test/cli_contract_test.dart --plain-name "runtime validator"` in the Nix dev
  shell; `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 21:44 JST
- State: `completed`
- Branch: `main`
- Active work: Enforce JSON/user-input-only nullable policy in Flutter CLI
  launch boundaries.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Restrict Flutter CLI nullable boundaries`).
- Purpose: apply the clarified policy that nullable values are allowed only at
  JSON and user-input boundaries, starting with launch configuration and process
  execution state that currently uses nullable working-directory sentinels.
- Completed work: replaced launch/process working-directory absence, process
  run observation, runtime install progress observation, one-shot program
  settings arguments, Wine-process termination scope, and launch non-empty
  string selection with explicit variants; removed the shared nullable
  `firstNonEmpty` helper; updated Flutter home-loader call sites and tests; and
  narrowed the custom-lint nullable allowance from the whole
  `apps/konyak/lib/src/cli` directory to direct JSON/result/process-input
  boundary files.
- Remaining work: continue applying the JSON/user-input-only nullable policy to
  broader Flutter app boundaries such as home-loader and UI adapter files when
  those areas are refactored.
- Next action: review the remaining broad app nullable boundary prefixes
  outside `apps/konyak/lib/src/cli` before tightening them file-by-file.
- Verification: observed the focused CLI client tests fail before
  implementation because the new process working-directory variants did not
  exist; after implementation, `flutter test test/cli/konyak_cli_client_test.dart`,
  `flutter pub run custom_lint`, `flutter analyze --fatal-infos`, `just
  flutter-format-check`, `just flutter-analyze`, `just flutter-test`, `just
  verify-governance`, `just verify-safety`, `just format-check`, and `just
  lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 21:34 JST
- State: `completed`
- Branch: `main`
- Active work: Batch CLI parser nullable sentinel cleanup.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `9f67e86` (`Type Winetricks parser results`).
- Purpose: continue the same nullable sentinel cleanup without stopping between
  parser files, while leaving the completed batch uncommitted for review.
- Completed work: added focused parser tests for update summaries, settings
  summaries, program metadata, and JSON error messages; replaced nullable
  parse-failure returns with sealed parse results across update, settings,
  program-run, program metadata, bottle program list, Wine process list, and
  JSON error-message parsing; and updated all affected callers.
- Remaining work: decide whether launch-configuration path resolution helpers
  should remain direct nullable adapter boundaries or be moved behind explicit
  result types before narrowing the nullable custom-lint allowance.
- Next action: review the remaining nullable-return helpers in
  `konyak_cli_launch_config.dart` and `konyak_cli_result_helpers.dart` as a
  separate boundary-design pass.
- Verification: observed focused update/settings/metadata/JSON-error helper
  tests fail before implementation because the new parse result types did not
  exist; after implementation, focused parser and related CLI client contract
  tests passed, and `just flutter-format-check`, `just flutter-analyze`, `just
  flutter-test`, `just verify-governance`, `just verify-safety`, `just
  format-check`, and `just lint` passed in the Nix dev shell. This batch is
  deliberately left uncommitted per request.

- Timestamp: 2026-06-29 21:13 JST
- State: `completed`
- Branch: `main`
- Active work: Type Winetricks payload parser results.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type Winetricks parser results`).
- Purpose: continue removing nullable success/failure sentinels from Flutter
  CLI contract parsers before narrowing nullable custom-lint allowances.
- Completed work: added focused Winetricks payload parser contract coverage;
  replaced category and verb helper nullable returns with explicit parse
  results; and updated verb-list parsing to switch on parsed/invalid category
  and verb records.
- Remaining work: continue nullable sentinel cleanup in the remaining Flutter
  CLI contract parsers, especially update/settings/program-run and
  launch-config helpers, before narrowing the nullable custom-lint allowance
  from directory level to direct boundary files.
- Next action: choose the next concentrated nullable parser boundary and repeat
  the same sealed-result cleanup.
- Verification: observed the focused Winetricks payload parser test fail before
  implementation because the new parse result types did not exist; after
  implementation, focused Winetricks payload parser and Winetricks CLI client
  contract tests passed, and `just flutter-format-check`, `just
  flutter-analyze`, `just flutter-test`, `just verify-governance`, `just
  verify-safety`, `just format-check`, and `just lint` passed in the Nix dev
  shell.

- Timestamp: 2026-06-29 21:04 JST
- State: `completed`
- Branch: `main`
- Active work: Type bottle record parser results.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `f8ba89f` (`Type bottle record parser results`).
- Purpose: continue removing nullable success/failure sentinels from Flutter
  CLI contract parsers before narrowing nullable custom-lint allowances.
- Completed work: added focused bottle record parser contract coverage; changed
  bottle summary, runtime settings, pinned-program, create conflict, detail
  not-found, and delete/list/detail/create bottle record parsing to use explicit
  sealed parse results instead of nullable success/failure sentinels.
- Remaining work: continue nullable sentinel cleanup in the remaining Flutter
  CLI contract parsers, especially Winetricks/update/settings/program-run and
  launch-config helpers, before narrowing the nullable custom-lint allowance
  from directory level to direct boundary files.
- Next action: choose the next concentrated nullable parser boundary and repeat
  the same sealed-result cleanup.
- Verification: observed the focused bottle record parser test fail before
  implementation because the new parse result types did not exist; after
  implementation, focused bottle record/create/detail/list/delete contract tests
  passed, and `just flutter-format-check`, `just flutter-analyze`, `just
  flutter-test`, `just verify-governance`, `just verify-safety`, `just
  format-check`, and `just lint` passed in the Nix dev shell.

- Timestamp: 2026-06-29 20:34 JST
- State: `completed`
- Branch: `main`
- Active work: Type runtime install progress parser results.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `e0ad865` (`Type runtime list parser results`).
- Purpose: continue removing nullable success/failure sentinels from Flutter
  CLI contract parsers before narrowing nullable custom-lint allowances.
- Completed work: updated runtime install progress contract tests to expect
  sealed parse results; changed progress payload parsing and runtime install
  error-message parsing to use explicit result variants; and updated the CLI
  runtime install progress callback bridge to switch on the parsed result.
- Remaining work: continue nullable sentinel cleanup in remaining Flutter CLI
  contract parsers, especially `bottle_record_contract.dart`, before narrowing
  the nullable custom-lint allowance from directory level to direct boundary
  files.
- Next action: continue with `bottle_record_contract.dart` parser helpers.
- Verification: observed the focused runtime install progress parser test fail
  before implementation because the new parse result types did not exist;
  after implementation, focused runtime install contract and CLI progress tests
  passed, and `just verify-governance`, `just verify-safety`, `just
  format-check`, `just lint`, and `just flutter-test` passed in the Nix dev
  shell.

- Timestamp: 2026-06-29 20:23 JST
- State: `completed`
- Branch: `main`
- Active work: Continue narrowing Flutter CLI parser nullable sentinels.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `6c60f25` (`Narrow CLI parser nullable sentinels`).
- Purpose: continue separating JSON boundary nullability from parser success
  and failure flow before narrowing the custom-lint nullable allowance.
- Completed work: changed runtime record parsing, runtime stack parsing, stack
  backend/component parsing, and string-list parsing to use sealed parse
  results instead of nullable success/failure sentinels; updated runtime
  install parsing to consume the new runtime record result.
- Remaining work: continue with other Flutter CLI contract parser helpers,
  especially bottle record/runtime install progress helpers, before narrowing
  the custom-lint nullable allowance from directory level to direct boundary
  files.
- Next action: continue nullable sentinel cleanup in `bottle_record_contract.dart`
  or `runtime_install_contract.dart`.
- Verification: focused runtime list and runtime install contract tests passed;
  `just verify-governance`, `just verify-safety`, `just format-check`, `just
  lint`, and `just flutter-test` passed in the Nix dev shell.

- Timestamp: 2026-06-29 20:13 JST
- State: `completed`
- Branch: `main`
- Active work: Narrow Flutter CLI adapter nullable responsibility.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit.
- Purpose: split nullable JSON/process boundary handling from command/result
  adapter code so `apps/konyak/lib/src/cli` no longer remains one broad
  nullable allowance.
- Completed work: replaced the bottle delete not-found parser helper and the
  graphics backend signal/suggestion parser helpers with private sealed parse
  results instead of nullable success/failure sentinels, while leaving external
  JSON `Object?` handling inside payload parser files.
- Remaining work: continue removing nullable sentinels from Flutter CLI
  contract parsers, especially runtime and bottle record contracts, then narrow
  the custom-lint nullable allowance from the whole `apps/konyak/lib/src/cli`
  directory to direct parser/process boundary files once those adapters are
  stable.
- Next action: continue with `runtime_list_contract.dart` or
  `bottle_record_contract.dart` parser helpers.
- Verification: focused Flutter CLI client tests for delete-bottle missing
  handling and graphics backend hints passed; `just verify-governance`, `just
  verify-safety`, `just format-check`, `just lint`, and `just flutter-test`
  passed in the Nix dev shell.

- Timestamp: 2026-06-29 19:45 JST
- State: `completed`
- Branch: `main`
- Active work: Continue functional-core domain type migration across CLI/domain
  boundaries.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Verify domain type boundary migration`).
- Purpose: keep raw CLI, JSON, and filesystem values at adapter boundaries
  while preserving domain value objects through runtime install, update,
  registry, program catalog, process, environment, graphics hint, Winetricks,
  mutation, and repository-facing APIs.
- Completed work: changed program pinned-program helpers, metadata extractor
  interfaces, graphics backend hint APIs, program and bottle mutation
  request/result models, runtime install source/package models, update records,
  registry update/query models, program environment builders, Wine process and
  program catalog records, Winetricks verb/category records, CLI parsers,
  repositories, I/O projections, launch manifest mapping, focused fixtures, and
  governance checks to preserve semantic value objects until JSON/I/O
  projection.
- Remaining work: broader primitive cleanup remains possible for
  schema/compatibility records that still model raw external contracts, such as
  runtime record/validation/source-manifest and Flutter-side contract adapters.
- Next action: choose the next narrow primitive-boundary candidate.
- Verification: `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, `just verify-governance`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed in the Nix dev shell.

- Timestamp: 2026-06-29 17:47 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for program location
  requests.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type program location requests`).
- Purpose: keep program location path requests typed as `ProgramPath` inside
  CLI/domain-facing location helpers instead of passing raw `--program`
  strings through the parser and platform helper.
- Completed work: added a failing typed program-location path fixture; changed
  `ProgramLocationOpenCliRequest.programPath`, the CLI location parser,
  `programLocationPath`, the location handler, and the Dart I/O path opener to
  preserve `ProgramPath` until boundary projection; and added governance
  coverage for the typed boundary.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program location paths use
  semantic value objects"` fail before implementation because
  `programLocationPath` still accepted raw `String`; after implementation the
  same focused test and `dart analyze --fatal-infos` passed; focused
  open-program-location CLI contract tests, `just verify-governance`, `just
  cli-test`, `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 17:33 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for bottle location
  requests.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type bottle location requests`).
- Purpose: keep bottle location path requests typed as `BottleLocation` inside
  CLI/domain-facing location helpers instead of passing raw `--location`
  strings through the platform helper.
- Completed work: added a failing typed bottle-location fixture; changed
  `BottleLocationOpenCliRequest.location`, the CLI location parser,
  `bottleLocationPath`, and the location handler to preserve `BottleLocation`
  until JSON projection; and added governance coverage for the boundary.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "bottle location paths use semantic
  value objects"` fail before implementation because `bottleLocationPath` still
  accepted raw `String`; after implementation the same focused test and `dart
  analyze --fatal-infos` passed; focused open-bottle-location CLI contract
  tests, `just verify-governance`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 17:05 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for runtime settings update
  helpers.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type runtime settings update helpers`).
- Purpose: keep runtime settings update helpers typed as `EnhancedSyncMode` and
  `DxvkHudMode` instead of accepting raw string setting values inside the
  domain model.
- Completed work: added a failing value-object setter fixture; changed
  `BottleRuntimeSettings.withEnhancedSync` and
  `BottleRuntimeSettings.withDxvkHud` to accept value objects and return
  private validated settings records; and added governance coverage for these
  setter boundaries.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime settings copyWith
  preserves semantic value object fields"` fail before implementation because
  the setters still accepted raw `String`; after implementation the same
  focused test and `dart analyze --fatal-infos` passed; `just
  verify-governance`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 16:53 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for bottle repository
  identity requests.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type bottle repository identity requests`).
- Purpose: keep bottle catalog lookup and bottle deletion requests typed as
  `BottleId` at repository-facing boundaries instead of passing raw CLI or test
  strings through the repository interface.
- Completed work: added a failing `BottleId` lookup fixture; introduced a CLI
  bottle-id parser helper; changed `BottleCatalog.findBottle`,
  `BottleRepository.deleteBottle`, file/memory/composite repository
  implementations, CLI read/mutation/location/program-run call sites, and
  direct test repository calls to preserve typed bottle IDs; and tightened
  governance so these repository boundaries do not return to raw strings.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "static catalogs expose immutable
  snapshots"` fail before implementation because `BottleCatalog.findBottle`
  still accepted raw `String`; after implementation the same focused test and
  `dart analyze --fatal-infos` passed; focused CLI/repository contract tests,
  `just verify-governance`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 16:32 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for runtime update service
  requests.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type runtime update service requests`).
- Purpose: keep runtime update and validation service requests typed as
  `RuntimeId`, and release metadata fetch requests typed as
  `RuntimeVersionUrl`, instead of passing raw strings through domain-facing
  interfaces.
- Completed work: committed typed Winetricks verb lister executable; added
  failing typed runtime-id and release metadata URL fixtures; changed
  `RuntimeUpdateChecker`, `RuntimeValidator`, `RuntimeReleaseMetadataFetcher`,
  CLI call sites, runtime update installation dispatch, I/O implementations,
  and recording fixtures to preserve typed runtime IDs and release metadata
  URLs; and tightened governance so these service boundaries do not return to
  raw strings.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed runtime update service request path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/cli_contract_test.dart --name "check-runtime-update --json returns
  machine-readable update status|validate-runtime --json returns runtime
  loader checks"` fail before implementation because the typed test fixtures
  did not match the old raw `String runtimeId` update checker and validator
  interfaces; also observed `cd packages/konyak_cli && dart test
  test/cli_contract_test.dart --name "runtime update checker uses source
  manifests from release metadata"` fail before implementation because
  `RuntimeReleaseMetadataFetcher.fetch` still accepted a raw `String`; after
  implementation, focused runtime update, validation, release metadata, and
  domain immutability tests, `dart analyze --fatal-infos`,
  `just verify-governance`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 16:16 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for Winetricks verb
  listing.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type Winetricks verb lister executable`).
- Purpose: keep the managed Winetricks executable typed as `ProgramExecutable`
  at the `WinetricksVerbLister` boundary instead of passing a raw `String`
  from repository selection into the process lister.
- Completed work: committed typed runtime executable probe requests; added a
  failing typed Winetricks lister fixture; changed `WinetricksVerbLister`,
  `DartIoWinetricksVerbRepository`, `DartIoWinetricksVerbLister`, and CLI
  recording fixtures to keep the executable typed as `ProgramExecutable`; and
  tightened governance so the lister boundary does not return to raw
  executable strings.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed Winetricks lister path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/cli_contract_test.dart --name "list-winetricks-verbs --json on Linux
  ignores stale macOS runtime verbs"` fail before implementation because the
  typed test fixture did not match the old raw `String executable` lister
  interface; after implementation, focused Winetricks CLI contract tests,
  `dart analyze --fatal-infos`, `just verify-governance`, `just cli-test`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 16:08 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for runtime executable
  probes.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type runtime executable probe requests`).
- Purpose: keep runtime validation probe execution requests typed as
  `ProgramExecutable`, `ProgramRunArguments`, and
  `ProgramWorkingDirectoryPath` instead of accepting raw process primitives at
  the domain-facing probe interface.
- Completed work: committed typed path opener targets; added a failing typed
  runtime executable probe contract; changed `RuntimeExecutableProbe`,
  `DartIoRuntimeExecutableProbe`, macOS/Linux runtime validation probe call
  sites, and CLI recording fixtures to pass typed executable, argv, and working
  directory values; and tightened governance so the probe interface does not
  return to raw process primitives.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed runtime executable probe path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime executable probes"` fail
  before implementation because the typed test fixture did not match the old
  raw `String` / `List<String>` / `String workingDirectory` probe interface;
  after implementation, focused runtime executable probe and runtime validator
  contract tests, `dart analyze --fatal-infos`, `just verify-governance`, full
  `test/domain_immutability_test.dart`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 16:01 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for path opening.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type path opener targets`).
- Purpose: keep OS open/reveal requests typed at the domain-facing
  `PathOpener` interface instead of accepting raw `String` targets.
- Completed work: committed typed detached process startup requests; added a
  failing typed path-opener contract; introduced `PathOpenTarget` and
  `PathRevealTarget`; changed `PathOpener`, `DartIoPathOpener`, app update,
  open URL, bottle-location, and program-location call sites to pass typed
  targets; updated CLI recording fixtures; and tightened governance so raw
  path-opener targets do not return at the domain interface or representative
  call sites.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed path-opener target path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "path openers"` fail before
  implementation because `PathOpenTarget` and `PathRevealTarget` did not
  exist; after implementation, focused path-opener and CLI contract tests,
  `dart analyze --fatal-infos`, `just verify-governance`, full
  `test/domain_immutability_test.dart`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 15:41 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for detached process
  startup.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: current commit (`Type detached process startup requests`).
- Purpose: keep detached process startup requests typed as `ProgramExecutable`
  and `ProgramRunArguments` at the domain interface instead of accepting raw
  `String` and `List<String>`.
- Completed work: committed typed terminal initial Wine commands; added a
  failing typed starter contract; changed `DetachedProcessStarter` and
  `DartIoDetachedProcessStarter` to accept `ProgramExecutable` and
  `ProgramRunArguments`; updated app update handoff call sites and CLI
  recording fixtures; and tightened governance so the detached-process domain
  interface does not return to raw primitive arguments.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed detached-process startup path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "detached process"` fail before
  implementation because the test fixture used typed detached-process requests
  against the old raw `String`/`List<String>` interface; after implementation,
  focused detached-process and app update handoff tests, `dart analyze
  --fatal-infos`, `just verify-governance`, full
  `test/domain_immutability_test.dart`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 15:29 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for terminal initial Wine
  commands.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `0b2a91f` (`Type terminal initial Wine commands`).
- Purpose: keep supported bottle commands typed as `BottleCommand` when the
  planner opens a terminal with an initial Wine command, instead of converting
  the command back to `String` at the request-builder boundary.
- Completed work: committed typed winedbg command planning; added a failing
  terminal command contract for `Option<BottleCommand>`; updated
  `ProgramRunPlanner`, Linux/macOS domain terminal request builders, legacy I/O
  request builders, and platform terminal command helpers to keep the initial
  Wine command typed as `BottleCommand`; and tightened governance so
  `Option<String> initialWineCommand` does not return.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed terminal initial-command path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "bottle commands"` fail before
  implementation with `BottleCommand` not assignable to `String`; after
  implementation, focused bottle-command tests, `dart analyze --fatal-infos`,
  `just verify-governance`, focused terminal CLI contract tests, full
  `test/domain_immutability_test.dart`, `just cli-test`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-29 15:19 JST
- State: `completed`
- Branch: `main`
- Active work: Tighten the functional-core boundary for Wine process debug
  request planning.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `6b9b9e7` (`Type winedbg command planning`).
- Purpose: replace the remaining raw `String`/`List<String>` winedbg request
  arguments at the planner/request-builder boundary with a typed domain plan
  while preserving the public CLI contract.
- Completed work: selected the winedbg process list/kill request path as the
  first narrow cleanup target; added a failing domain test for typed winedbg
  command plans; introduced `WinedbgCommand`, `ProgramLogFileName`, and
  `WinedbgCommandPlan`; moved process list/kill command names, log file names,
  and trailing arguments into command-support plan helpers; updated Linux/macOS
  domain and platform request builders to accept the typed plan; and updated
  governance so primitive winedbg request arguments do not return.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`,
  including other primitive request/planner APIs and later strategy extraction
  if the Linux/macOS switch grows.
- Next action: continue with the next narrow primitive-boundary cleanup outside
  the completed winedbg process plan path.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "Wine process"` fail before
  implementation with missing typed plan/value objects; after implementation,
  `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format ...`, focused Wine process
  domain tests, `dart analyze --fatal-infos`, focused
  `cli_contract_test.dart` Wine process tests, full
  `test/domain_immutability_test.dart`, `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed.

- Timestamp: 2026-06-29 15:04 JST
- State: `completed`
- Branch: `main`
- Active work: Document why map-snapshot value objects stay hand-written.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `227e916` (`Use Freezed copyWith for bottle records`).
- Purpose: record the design decision from the Freezed cleanup pass so future
  mechanical conversions do not expose internal immutable-map storage through
  generated fields or `copyWith`.
- Completed work: inspected `ProgramEnvironmentOverrides`,
  `ProgramRunEnvironment`, `HostEnvironment`, and `RuntimeComponentVersions`;
  confirmed each accepts raw `Map<String, String>` input and hides validated
  immutable value-object storage; added local why-not-Freezed notes to those
  classes.
- Remaining work: broader functional-core tightening remains in `docs/todo.md`;
  these map-snapshot classes are now an intentional exception unless a future
  design introduces a dedicated domain collection value object first.
- Next action: continue with the next mechanical Freezed or primitive-boundary
  cleanup outside the hidden-map snapshot classes.
- Verification: `dart format
  packages/konyak_cli/lib/src/domain/program/program_run_environment.dart
  packages/konyak_cli/lib/src/domain/runtime/host_environment.dart
  packages/konyak_cli/lib/src/domain/runtime/runtime_component_versions.dart`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed.

- Timestamp: 2026-06-29 14:58 JST
- State: `completed`
- Branch: `main`
- Active work: Replace legacy bottle record wrappers with Freezed copyWith.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Use Freezed copyWith for bottle records`).
- Purpose: continue the Freezed cleanup by removing compatibility `withX`
  wrappers from `BottleRecord` and `PinnedProgramRecord` and moving call sites
  to generated `copyWith`.
- Completed work: committed the completed bottle mutation/runtime settings
  Freezed batch; inspected remaining wrapper call sites in storage,
  repository, I/O, pinned program helpers, and domain immutability tests; added
  focused `BottleRecord.copyWith` and `PinnedProgramRecord.copyWith` coverage
  and observed it fail while `copyWith` was disabled; enabled generated
  `copyWith`, removed legacy `withX` wrappers from `BottleRecord` and
  `PinnedProgramRecord`, updated call sites to typed `copyWith`, and tightened
  governance so those wrappers do not return.
- Remaining work: map-snapshot models such as `ProgramRunEnvironment`,
  `HostEnvironment`, and `RuntimeComponentVersions` still use hand-written
  equality; these require a separate decision because Freezed would otherwise
  expose internal immutable-map fields.
- Next action: either commit this completed wrapper cleanup or inspect the
  map-snapshot models for a design that preserves hidden storage.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "bottle records copyWith preserves
  semantic value object fields|pinned program records copyWith preserves
  semantic fields"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/bottle/bottle_models.dart
  lib/src/domain/program/pinned_programs.dart lib/src/io/bottle_archives.dart
  lib/src/io/program_registry_parsers.dart
  lib/src/repository/file_bottle_repository_mutation_operations.dart
  lib/src/repository/memory_bottle_repository.dart
  lib/src/storage/storage_paths.dart test/domain_immutability_test.dart &&
  dart analyze --fatal-infos`, focused bottle/pinned `copyWith` tests,
  focused pinned-program and bottle mutation CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 14:20 JST
- State: `completed`
- Branch: `main`
- Active work: Batch Freezed conversion for mechanical bottle domain records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `a9357f2` (`Freezed app settings record`).
- Purpose: convert the remaining mechanically simple hand-written bottle
  domain records to Freezed without changing public CLI contracts.
- Completed work: inspected the current hand-written domain model scan,
  `bottle_mutation_models.dart`, `bottle_runtime_settings_models.dart`,
  mutation/result switch sites, repository constructor tear-offs, and runtime
  settings `withX` call sites; selected `bottle_mutation_models.dart` and
  `BottleRuntimeSettings` as the safe batch because they are pure value/result
  models and their behavior can be covered with focused semantic equality and
  `copyWith` tests; added focused tests and observed the runtime settings
  `copyWith` test fail before implementation; converted bottle mutation
  request/record classes and concrete result variants to Freezed while
  preserving existing constructor names and switch pattern class names;
  converted `BottleRuntimeSettings` to Freezed while keeping existing `withX`
  helpers for compatibility; updated governance so the bottle archive JSON
  projection check recognizes Freezed class shapes.
- Remaining work: map-snapshot models such as `ProgramRunEnvironment`,
  `HostEnvironment`, and `RuntimeComponentVersions` still use hand-written
  equality; `BottleRecord`/`PinnedProgramRecord` still expose legacy `withX`
  wrappers over Freezed.
- Next action: either commit this completed batch or inspect the remaining
  map-snapshot models before deciding whether they are safe to convert.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "bottle mutation request records
  compare by semantic values|bottle mutation result records compare by semantic
  values|runtime settings copyWith preserves semantic value object fields"`
  fail before implementation; after implementation, `cd packages/konyak_cli &&
  dart run build_runner build --delete-conflicting-outputs && dart format
  lib/src/domain/bottle/bottle_mutation_models.dart
  lib/src/domain/bottle/bottle_runtime_settings_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  bottle mutation/runtime settings tests, focused bottle mutation CLI contract
  tests, `cd packages/konyak_cli && dart test test/domain_immutability_test.dart`,
  `just verify-governance`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 14:07 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed app settings record.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed app settings record`).
- Purpose: continue removing hand-written domain value boilerplate by
  converting `AppSettingsRecord` to Freezed and replacing its manual `withX`
  methods with generated `copyWith`.
- Completed work: committed the completed `ProgramRunRequest` Freezed slice;
  inspected remaining hand-written domain records and selected
  `AppSettingsRecord` because it is a single value record with manual
  equality/hashCode and no external `withX` call sites; added focused
  `copyWith` coverage and observed it fail against the hand-written record;
  converted the record to Freezed with a private validated factory while
  preserving the public `String defaultBottlePath` constructor boundary and
  replacing manual `withX` helpers with generated `copyWith`.
- Remaining work: continue the broader Freezed scan with larger hand-written
  records such as bottle mutation requests/results or bottle runtime settings.
- Next action: inspect the next hand-written record group by risk and
  call-site breadth.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "app settings copyWith preserves
  semantic value object fields"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/app/app_settings_models.dart test/domain_immutability_test.dart
  && dart analyze --fatal-infos`, focused app settings `copyWith` test,
  focused app-settings CLI contract tests, `cd packages/konyak_cli && dart
  test test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-safety`, `just format-check`, `just lint`, and `just cli-test`
  passed.

- Timestamp: 2026-06-29 14:01 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program run request.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `ddc418e` (`Freezed Wine process termination records`);
  working tree contains the completed uncommitted implementation.
- Purpose: finish the hand-written value records in
  `program_run_models.dart` by converting `ProgramRunRequest` while preserving
  its typed constructor and derived `argv` getter.
- Completed work: inspected `ProgramRunRequest` call sites, `const`/`copyWith`
  usage, CLI JSON/log projections, existing request tests, and typed-boundary
  governance; confirmed call sites use ordinary `ProgramRunRequest(...)`
  construction and do not depend on `const` or `copyWith`; added focused
  value-semantics coverage and observed it fail against the hand-written
  record; converted `ProgramRunRequest` to Freezed with a private factory while
  keeping `argv` derived; updated governance for Freezed class shapes.
- Remaining work: commit this completed implementation if accepted, then
  continue the broader Freezed scan outside `program_run_models.dart`.
- Next action: review/commit the current working tree or continue with the
  next hand-written domain record group.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program run requests expose
  semantic value object fields"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_run_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program run request test, focused run-program CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:50 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed Wine process termination record.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed Wine process termination records`).
- Purpose: continue the `program_run_models.dart` Freezed pass with the
  remaining process termination value record before evaluating
  `ProgramRunRequest`.
- Completed work: committed the program run result union Freezed slice;
  inspected `WineProcessTerminationRecord` construction sites, immutable argv
  tests, and JSON projection governance; selected this record because it has
  few call sites and its list snapshot contract is already tested; added
  focused value-semantics coverage and observed it fail against the
  hand-written record; converted the record to Freezed while preserving
  value-object coercion and unmodifiable argv snapshots; updated governance
  class-section detection for Freezed class shapes.
- Remaining work: `ProgramRunRequest` remains hand-written in
  `program_run_models.dart`; it is broader because it exposes derived `argv`.
- Next action: inspect whether `ProgramRunRequest` can be converted with a
  private Freezed factory while preserving the derived `argv` getter and typed
  constructor governance.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "process termination records
  expose immutable argv snapshots"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs`, `cd packages/konyak_cli && dart format
  lib/src/domain/program/program_run_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  process termination record test, focused terminate-wine-process CLI contract
  tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed. A mistaken attempt to include
  `scripts/verify_governance.py` in `dart format` failed and was corrected by
  rerunning Dart format on Dart files only.

- Timestamp: 2026-06-29 13:46 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program run result unions.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program run results`).
- Purpose: continue the program-domain Freezed scan by converting the narrow
  result unions in `program_run_models.dart` before touching the broader
  `ProgramRunRequest` record.
- Completed work: committed the program settings record Freezed slice;
  inspected `ProgramRunResult`, `PathOpenResult`, and
  `DetachedProcessStartResult` call sites; selected these unions because they
  have simple payloads and existing concrete switch pattern names can be
  preserved; added focused value-semantics coverage and observed it fail
  against the hand-written result classes; converted the result unions to
  Freezed while preserving direct concrete constructors and pattern names.
- Remaining work: `ProgramRunRequest` and `WineProcessTerminationRecord` remain
  hand-written in `program_run_models.dart`; both are larger because they
  expose derived argv or immutable list snapshots.
- Next action: inspect `ProgramRunRequest` and `WineProcessTerminationRecord`
  for the next low-risk record conversion, starting with
  `WineProcessTerminationRecord` if its list snapshot contract can be preserved
  cleanly.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program run result unions compare
  by semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_run_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program run result-union value-semantics test, focused ProgramRun/PathOpen/
  DetachedProcessStart CLI contract tests, `cd packages/konyak_cli && dart
  test test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:42 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program settings records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program settings records`).
- Purpose: continue the program-domain Freezed scan with the smallest
  remaining hand-written program settings value records.
- Completed work: inspected `program_settings_models.dart`,
  `program_run_models.dart`, and current tests; selected
  `ProgramSettingsRecord` and `ProgramLoggingSettingsRecord` because they are
  pure value records with existing manual equality and no result branching;
  added focused value-semantics coverage for settings/logging; converted both
  records to Freezed while preserving public constructor defaults and
  value-object coercion; updated governance class-section and typed
  environment checks for Freezed class shapes.
- Remaining work: continue the Freezed scan with the larger program run model
  group, likely starting with narrow result unions in `program_run_models.dart`
  before the broader `ProgramRunRequest`.
- Next action: inspect `ProgramRunResult`, `PathOpenResult`, and
  `DetachedProcessStartResult` call sites for the next low-risk result-union
  slice.
- Verification: `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program settings records compare
  by semantic values"` passed before implementation as behavior-preserving
  coverage; after implementation, `cd packages/konyak_cli && dart run
  build_runner build --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_settings_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  settings record/results/environment tests, focused program settings CLI
  contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:28 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed registry value records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed registry value records`).
- Purpose: continue the program-domain Freezed scan with the smallest
  remaining hand-written program model file.
- Completed work: committed the program update result Freezed slice; inspected
  `program_registry_models.dart`, `program_registry_plans.dart`, and registry
  request call sites; selected `RegistryValueUpdate` and
  `RegistryValueQuery` because they are pure value records with named-field
  construction and no branching; added focused value-semantics coverage and
  observed it fail after avoiding `const` canonicalization; converted the
  registry value records to Freezed.
- Remaining work: continue the Freezed scan with the larger program run model
  group, likely starting with `program_settings_models.dart` or the narrow
  result unions in `program_run_models.dart`.
- Next action: inspect `program_settings_models.dart` and
  `program_run_models.dart` to choose the next smallest hand-written
  value/result model slice.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "registry value records compare by
  semantic values"` fail before implementation after removing `const`; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_registry_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  registry value-semantics test, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:24 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program update result union.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program update results`).
- Purpose: finish the hand-written result unions in
  `program_mutation_models.dart` by converting `ProgramUpdateResult`.
- Completed work: committed the program pin result Freezed slice; inspected
  update result variants, CLI JSON projection, repository call sites, and
  governance baselines; selected `ProgramUpdateResult` as the last
  hand-written result union in this file; added focused value-semantics
  coverage and observed it fail against missing base factories; converted
  `ProgramUpdateResult` to Freezed with base factories for missing bottle and
  missing program conversion; updated repository call sites and
  result-boundary governance.
- Remaining work: continue the Freezed scan outside
  `program_mutation_models.dart`, with the next likely low-risk group in the
  program registry models/plans.
- Next action: inspect `program_registry_models.dart`,
  `program_registry_plans.dart`, and nearby program domain files for the next
  hand-written value/result model slice.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program update results compare
  by semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_mutation_models.dart
  lib/src/repository/file_bottle_repository_program_operations.dart
  lib/src/repository/memory_bottle_repository.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program update result value-semantics test, focused unpin/rename pinned
  program CLI contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:18 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program pin result union.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program pin results`).
- Purpose: continue the program mutation Freezed pass by converting
  `ProgramPinResult` before the broader program update result union.
- Completed work: committed the settings result Freezed slice; inspected pin
  result variants and call sites; selected `ProgramPinResult` because it has a
  single success payload plus missing/conflict/failure variants with simple
  value-object conversions; added focused value-semantics coverage and observed
  it fail against the hand-written result variants; converted
  `ProgramPinResult` to Freezed with base factories for missing bottle and
  conflict path conversion; updated construction call sites and result-boundary
  governance.
- Remaining work: `ProgramUpdateResult` remains hand-written in
  `program_mutation_models.dart`.
- Next action: convert `ProgramUpdateResult`, preserving concrete switch
  pattern names and using base factories for missing bottle, missing program,
  and failed variants.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program pin results compare by
  semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_mutation_models.dart
  lib/src/repository/file_bottle_repository_program_operations.dart
  lib/src/repository/memory_bottle_repository.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program pin result value-semantics test, focused pin-program and
  launch-pinned-program CLI contract tests, focused settings and mutation
  request value-semantics tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  cli-test`, and `just lint` passed.

- Timestamp: 2026-06-29 13:13 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program settings result unions.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program settings results`).
- Purpose: continue the program mutation Freezed pass with the narrow
  settings read/update result unions before touching broader pin/update
  mutation results.
- Completed work: committed the program mutation request record Freezed slice;
  inspected settings result variants and call sites; selected
  `ProgramSettingsReadResult` and `ProgramSettingsUpdateResult` because their
  variants only wrap settings records, missing bottle ids, or failure messages;
  added focused value-semantics coverage and observed it fail against the
  missing base factories; converted both settings result unions to Freezed with
  base factories for missing bottle id conversion; updated repository and test
  construction call sites; updated result-boundary governance to allow Freezed
  failed factories for the settings result variants.
- Remaining work: `ProgramPinResult` and `ProgramUpdateResult` remain
  hand-written in `program_mutation_models.dart`.
- Next action: convert `ProgramPinResult` first, preserving concrete switch
  pattern names and using base factories for missing/conflict value-object
  conversion.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program settings results compare
  by semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_mutation_models.dart
  lib/src/repository/file_bottle_repository_program_operations.dart
  lib/src/repository/composite_bottle_repository.dart
  lib/src/repository/memory_bottle_repository.dart
  test/domain_immutability_test.dart test/cli_contract_test.dart && dart
  analyze --fatal-infos`, focused settings result value-semantics test,
  focused settings CLI contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:07 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program mutation request records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program mutation request records`).
- Purpose: continue the Freezed domain model pass with the low-risk
  `program_mutation_models.dart` request and manifest records before touching
  the result unions.
- Completed work: committed the winetricks verb-list result slice; inspected
  `program_mutation_models.dart`, `program_registry_models.dart`, and
  `program_registry_plans.dart`; selected request/manifest records because
  they only wrap existing value objects or `Option` values and have no result
  branching; added focused value-semantics coverage and observed it fail
  against the hand-written request records; converted `ProgramPinRequest`,
  `ProgramUnpinRequest`, `ProgramRenameRequest`,
  `PinnedProgramLauncherManifest`, `WineProcessTerminationRequest`,
  `WineProcessGroupTerminationRequest`, `ProgramSettingsRequest`, and
  `ProgramSettingsUpdateRequest` to Freezed; updated the pinned launcher
  manifest governance regex for Freezed class syntax.
- Remaining work: `program_mutation_models.dart` still has hand-written result
  unions: `ProgramPinResult`, `ProgramUpdateResult`,
  `ProgramSettingsReadResult`, and `ProgramSettingsUpdateResult`.
- Next action: convert the program mutation result unions in small groups,
  starting with `ProgramSettingsReadResult` and
  `ProgramSettingsUpdateResult` because their variants are the narrowest.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program mutation request records
  compare by semantic values"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_mutation_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program mutation request value-semantics test, focused pin/unpin/rename
  program settings and terminate-wine-process CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 13:01 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed winetricks verb list result.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed winetricks verb list results`).
- Purpose: finish the program catalog Freezed pass by converting the remaining
  winetricks result union while preserving category list snapshots.
- Completed work: committed the winetricks verb/category record Freezed slice;
  inspected the result union, winetricks IO call sites, CLI JSON switch
  patterns, and tests; selected a base `WinetricksVerbListResult.completed`
  factory that can snapshot categories before exposing the existing concrete
  `WinetricksVerbListCompleted` pattern; added focused value-semantics and
  snapshot coverage and observed it fail against the hand-written result
  classes; converted `WinetricksVerbListResult` to Freezed with `IList`
  completed categories; updated direct completed/failed construction in
  winetricks IO and tests to the base factories while preserving switch
  pattern concrete names.
- Remaining work: `program_catalog_models.dart` is now Freezed-backed for the
  program records, winetricks records, and winetricks verb-list result. Continue
  the broader Freezed scan with the next hand-written domain model group.
- Next action: inspect `program_mutation_models.dart`,
  `program_registry_models.dart`, and `program_registry_plans.dart` for the
  next low-risk record/result slice.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "winetricks verb list results
  compare by value"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_catalog_models.dart lib/src/io/winetricks_io.dart
  test/domain_immutability_test.dart test/cli_contract_test.dart
  test/cli_contract_program_execution.part.dart && dart analyze
  --fatal-infos`, focused winetricks result value-semantics test, focused
  list-winetricks-verbs / run-winetricks CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 12:55 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed winetricks catalog records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed winetricks catalog records`).
- Purpose: continue the program catalog Freezed pass by converting the
  winetricks verb/category records before touching the result union.
- Completed work: committed the core program catalog record Freezed slice;
  inspected winetricks parser, CLI JSON projection, result handling, and call
  sites; selected `WinetricksVerbRecord` and `WinetricksCategoryRecord` as the
  next slice because the category list snapshot can be preserved independently
  from `WinetricksVerbListResult`; added focused value-semantics and
  immutable-list snapshot coverage and observed it fail against the
  hand-written records; converted the two winetricks catalog records to
  Freezed while preserving public String-taking factories and the category
  list snapshot.
- Remaining work: `WinetricksVerbListResult` remains hand-written in
  `program_catalog_models.dart`.
- Next action: convert `WinetricksVerbListResult` result variants to Freezed,
  preserving concrete variant constructor names and category list snapshots in
  completed results.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "winetricks catalog records expose
  immutable value snapshots"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_catalog_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  winetricks catalog value-semantics test, focused list-winetricks-verbs CLI
  contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 12:50 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program catalog core records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program catalog records`).
- Purpose: continue the Freezed domain model pass with the low-risk program
  catalog records before touching list-snapshot winetricks records or result
  variants.
- Completed work: inspected `program_catalog_models.dart`, CLI JSON projection
  governance, result-boundary governance, and call sites; selected
  `BottleProgramRecord`, `ProgramMetadataRecord`, and `WineProcessRecord` as
  the first catalog slice because they only wrap value objects and `Option`
  metadata without list snapshots or result branching; added focused
  value-semantics coverage and observed it fail against the hand-written
  records; converted the three records to Freezed while preserving public
  String-taking factories; updated governance baselines from hand-written
  `final Option<...>` fields to Freezed private factory `required
  Option<...>` fields.
- Remaining work: `WinetricksVerbRecord`, `WinetricksCategoryRecord`, and
  `WinetricksVerbListResult` remain hand-written in
  `program_catalog_models.dart`. The list-snapshot category record should be
  handled before the result variants.
- Next action: convert the winetricks catalog records with value-semantics
  coverage, preserving immutable verb/category snapshots and CLI JSON output.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "program catalog records compare
  by semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/program/program_catalog_models.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  program catalog value-semantics tests, focused list-bottle-programs /
  list-wine-processes CLI contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 12:37 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime update check result variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed runtime update results`).
- Purpose: finish the update result variant Freezed pass by converting the
  remaining runtime update check result union with explicit handling for the
  not-found value-object conversion.
- Completed work: committed the app update result Freezed slice; confirmed
  `RuntimeUpdateCheckResult` is the remaining hand-written result union in
  `update_records.dart`; identified `RuntimeUpdateRuntimeNotFound` as the only
  variant requiring String-to-`RuntimeId` construction; added focused
  value-semantics coverage and observed it fail against the hand-written
  result classes; converted `RuntimeUpdateCheckResult` to Freezed with a
  public `runtimeNotFound(String runtimeId)` factory; updated direct not-found
  construction in the runtime update checker to use the base factory while
  preserving `RuntimeUpdateRuntimeNotFound` switch pattern names.
- Remaining work: `update_records.dart` is now Freezed-backed for its records
  and result variants. Continue the broader Freezed scan with program catalog
  records or program run result variants; map wrappers with const/equality
  constraints remain deferred.
- Next action: inspect `program_catalog_models.dart` records and result
  variants for a low-risk Freezed slice, starting with simple records before
  touching list/result variants.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime update check results
  compare by value"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/update/update_records.dart
  lib/src/io/runtime_update_checker_io.dart test/domain_immutability_test.dart
  && dart analyze --fatal-infos`, focused runtime update result
  value-semantics test, focused runtime update CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 12:34 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed app update result variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed app update results`).
- Purpose: continue the update result variant Freezed pass with result unions
  that do not perform primitive-to-value-object conversion.
- Completed work: committed the release metadata fetch result Freezed slice;
  selected `AppUpdateCheckResult` and `AppUpdateInstallResult` because their
  variants only wrap validated records or failure messages and can preserve
  existing concrete constructor usage; added focused value-semantics coverage
  and observed it fail against the hand-written result classes; converted both
  app update result unions to Freezed while preserving
  `AppUpdateCheckCompleted`, `AppUpdateCheckFailed`,
  `AppUpdateInstallCompleted`, and `AppUpdateInstallFailed` concrete
  constructor usage.
- Remaining work: `RuntimeUpdateCheckResult` remains hand-written.
  `RuntimeUpdateRuntimeNotFound` still performs String-to-`RuntimeId`
  conversion, so it needs a call-site-aware Freezed slice.
- Next action: convert `RuntimeUpdateCheckResult` with a public base factory
  for `runtimeNotFound(String runtimeId)` and update direct not-found
  construction to use that factory while preserving switch pattern names.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "app update results compare by
  value"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/update/update_records.dart test/domain_immutability_test.dart
  && dart analyze --fatal-infos`, focused app update result value-semantics
  test, focused app update CLI contract tests, `cd packages/konyak_cli && dart
  test test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just lint`,
  and `just cli-test` passed.

- Timestamp: 2026-06-29 12:30 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime release metadata fetch result variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed release metadata fetch results`).
- Purpose: continue the update result variant Freezed pass with the smallest
  low-risk result union before touching variants that perform String-to-value
  object conversion.
- Completed work: committed the update record Freezed slice; scanned direct
  update result variant constructor usage across CLI, IO, domain, and tests;
  selected `RuntimeReleaseMetadataFetchResult` because its variants only wrap
  an already-validated metadata record or failure message and can preserve the
  existing concrete constructor names; added focused result value-semantics
  coverage and observed it fail against the hand-written result classes;
  converted `RuntimeReleaseMetadataFetchResult` to Freezed while preserving
  `RuntimeReleaseMetadataFetched` and `RuntimeReleaseMetadataFetchFailed`
  concrete constructor usage.
- Remaining work: `RuntimeUpdateCheckResult`, `AppUpdateCheckResult`, and
  `AppUpdateInstallResult` remain hand-written. `RuntimeUpdateRuntimeNotFound`
  still performs String-to-`RuntimeId` conversion, so that slice needs call-site
  planning rather than a blind union conversion.
- Next action: evaluate `AppUpdateCheckResult` and `AppUpdateInstallResult`
  first, because their variants do not perform value-object conversion and can
  likely preserve direct concrete constructors.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime release metadata fetch
  results compare by value"` fail before implementation; after implementation,
  `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/update/update_records.dart test/domain_immutability_test.dart
  && dart analyze --fatal-infos`, focused metadata fetch result
  value-semantics test, focused release metadata/update CLI contract tests, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 12:21 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed update domain records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed update records`).
- Purpose: continue the Freezed domain model pass with update records while
  keeping higher-risk result variants and CLI contracts out of this slice.
- Completed work: committed the graphics backend hint Freezed slice; inspected
  `update_records.dart`, update CLI JSON projection, runtime/app update call
  sites, and governance checks; selected the four update record classes
  (`RuntimeUpdateRecord`, `AppUpdateRecord`, `AppUpdateInstallRecord`, and
  `RuntimeReleaseMetadata`) as the next narrow conversion target; added focused
  value-semantics coverage and observed it fail against the hand-written record
  classes; converted the four update records to Freezed while preserving
  primitive-to-value-object construction and `Option` mapping; left update
  result variants hand-written for a separate slice; updated governance
  baselines so update records can be Freezed-backed while still requiring
  domain-facing absence to use `Option` and CLI JSON projection to stay outside
  domain models.
- Remaining work: update result variants remain hand-written; map wrappers with
  const/equality constraints remain deferred; continue the Freezed scan with
  update result variants or program catalog records depending on call-site
  risk.
- Next action: inspect `RuntimeUpdateCheckResult`, `AppUpdateCheckResult`,
  `AppUpdateInstallResult`, and `RuntimeReleaseMetadataFetchResult` for a
  result-variant Freezed slice, especially direct concrete constructor usage in
  update checker and release metadata tests.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "update records compare by
  semantic values"` fail before implementation; after implementation, `cd
  packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs`, `cd packages/konyak_cli && dart format
  lib/src/domain/update/update_records.dart test/domain_immutability_test.dart
  && dart analyze --fatal-infos`, focused update record value-semantics test,
  focused update record immutability tests, focused `update` CLI contract
  tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just lint`,
  and `just cli-test` passed.

- Timestamp: 2026-06-29 12:14 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed program graphics backend hint records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed program graphics backend hints`).
- Purpose: continue replacing hand-written immutable domain model boilerplate
  with Freezed-backed records, starting with the narrow graphics backend hint
  records and inspection result variants before higher-risk update/program run
  models.
- Completed work: selected `program_graphics_backend_hints.dart` as the next
  non-map candidate after deferring map wrappers with const/equality
  constraints; inspected current progress, TODOs, direct call sites, CLI JSON
  projection, and existing Freezed model patterns; added focused
  value/immutability coverage and observed it fail against the hand-written
  record classes; converted graphics backend hint records and inspection result
  variants to Freezed while preserving primitive-to-value-object construction
  at the domain boundary; changed missing/failed inspection construction to
  base factories; kept JSON projection in the CLI layer and fixed graphics
  backend error JSON to emit `programPath.value`; updated governance class
  detection so the existing no-domain-`toJson` check recognizes Freezed-backed
  abstract classes.
- Remaining work: map wrappers with const/equality constraints remain deferred;
  continue the Freezed scan with a slightly higher-risk non-map candidate such
  as update records, program catalog records, or program run result variants.
- Next action: inspect `update_records.dart` result/record constructors and
  select the smallest Freezed conversion slice that preserves CLI JSON
  contracts.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "graphics backend hints expose
  immutable value records"` fail before implementation; after implementation,
  `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs`, `cd packages/konyak_cli && dart format
  lib/src/domain/program/program_graphics_backend_hints.dart
  lib/src/io/program_graphics_backend_hints_io.dart
  lib/src/cli/cli_program_run_handlers.dart test/domain_immutability_test.dart
  test/cli_contract_test.dart && dart analyze --fatal-infos`, focused graphics
  backend hint immutability test, focused `suggest-graphics-backend` CLI
  contract tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just lint`,
  and `just cli-test` passed.

- Timestamp: 2026-06-29 11:39 JST
- State: `completed`
- Branch: `main`
- Active work: remove the runtime install request accessor wrapper.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Remove runtime install accessor wrapper`).
- Purpose: continue the install-operation cleanup by removing a now-redundant
  one-field forwarding wrapper after request operations became Freezed-backed.
- Completed work: committed the request operation Freezed slice; scanned
  remaining runtime/domain wrappers and confirmed
  `RuntimeWineInstallRequestAccessors` only forwarded getters from
  `RuntimeInstallRequestOperation` to macOS/Linux platform request wrappers;
  changed the platform request wrappers to store `RuntimeInstallRequestOperation`
  directly; deleted the forwarding accessor class.
- Remaining work: `RuntimeComponentVersions` and `HostEnvironment` remain
  hand-written map wrappers with const/equality constraints; continue scanning
  non-map hand-written domain records and result variants for the next narrow
  candidate.
- Next action: select the next non-map hand-written domain model candidate,
  likely from program/update/bottle mutation records, and verify whether it can
  be moved to Freezed without widening public contracts.
- Verification: `cd packages/konyak_cli && dart format
  lib/src/domain/runtime/runtime_install_operation_models.dart
  lib/src/platform/macos/macos_wine_install_requests.dart
  lib/src/platform/linux/linux_wine_install_requests.dart && dart analyze
  --fatal-infos`, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime install operations"`, `cd
  packages/konyak_cli && dart test test/cli_contract_test.dart --name
  "install-macos-wine --source-manifest passes the source
  manifest|install-linux-wine --source-manifest passes the source
  manifest|install-linux-wine builds a stack from component
  archives|install-macos-wine builds a stack from component archives"`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 11:26 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime install request operation variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed runtime install operations`).
- Purpose: finish the install-operation model Freezed pass by converting the
  remaining request operation variants after the source/checksum/signature
  variants were stabilized.
- Completed work: inspected direct request operation constructor usage and
  confirmed it is limited to platform request wrappers, domain immutability
  tests, and the current model definitions; added focused operation snapshot
  coverage and observed it fail before implementation; converted
  `RuntimeInstallRequestOperation` to Freezed-backed variants with public base
  factories for full install, repair, component install, and update install;
  updated platform request wrappers and domain tests to use those base
  factories; preserved existing variant pattern names, `operation`, `force`,
  `installSource`, derived source accessors, and immutable component archive
  path snapshots; updated governance to require the new Freezed operation
  factory baseline.
- Remaining work: `runtime_install_operation_models.dart` is now Freezed-backed
  for checksum, signature, install source, and request operation variants. The
  next candidate should be selected from the remaining hand-written runtime
  domain wrappers or from another TODO item after a fresh scan.
- Next action: scan remaining runtime/domain hand-written immutable wrappers
  and choose the next narrow candidate, while keeping `RuntimeComponentVersions`
  deferred unless its public constructor/equality constraints are simplified.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime install operations"` fail
  before implementation; after implementation, `cd packages/konyak_cli && dart
  run build_runner build --delete-conflicting-outputs && dart format
  lib/src/domain/runtime/runtime_install_operation_models.dart
  lib/src/platform/macos/macos_wine_install_requests.dart
  lib/src/platform/linux/linux_wine_install_requests.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  operation tests, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 11:17 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime install source variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed runtime install sources`).
- Purpose: continue replacing hand-written install operation model boilerplate
  by converting the runtime install source variants after the checksum and
  signature variants were stabilized.
- Completed work: committed the checksum/signature slice; inspected
  `RuntimeInstallSource` direct constructor usage and confirmed repo call sites
  are limited to model construction in `runtime_install_operation_models.dart`
  plus switch patterns in install planning/accessors; added focused source
  snapshot coverage and observed it fail before implementation; converted
  `RuntimeInstallSource` to Freezed-backed variants with public base factories
  for configured, local, remote, and source-manifest sources; preserved existing
  switch pattern names, value-object conversion, `hasExplicitInstallSource`,
  and immutable component archive path snapshots; updated governance to require
  the new Freezed source factory baseline instead of hand-written `final class`
  variants.
- Remaining work: `RuntimeInstallRequestOperation` variants remain hand-written
  and are the next install-operation model candidate.
- Next action: evaluate `RuntimeInstallRequestOperation` variants for a narrow
  Freezed conversion slice while preserving `operation`, `force`, and
  `installSource` accessors.
- Verification: observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime install sources expose
  immutable archive path snapshots"` fail before implementation; after
  implementation, `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/runtime/runtime_install_operation_models.dart
  lib/src/domain/runtime/runtime_install_plans.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, focused
  source snapshot test, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`, `just
  verify-architecture`, `just verify-safety`, `just format-check`, `just
  lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 11:12 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime install checksum and signature variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `96d12ee` (`Freezed runtime install plans`).
- Purpose: continue replacing hand-written immutable domain model boilerplate
  in `runtime_install_operation_models.dart` with a narrow, low-risk slice
  before touching the larger install source and operation constructors.
- Completed work: inspected install operation models, existing immutability
  coverage, and repo call sites for direct concrete checksum/signature
  constructor usage; no repo call sites instantiate the concrete variants
  directly outside the model definitions; converted `RuntimeArchiveChecksum`
  and `RuntimeSourceManifestSignature` variants to Freezed-backed variants with
  `copyWith` disabled while preserving public string-taking factories,
  existing pattern names, `asOption`, and blank value validation through value
  objects; regenerated the local ignored
  `runtime_install_operation_models.freezed.dart`.
- Remaining work: larger `RuntimeInstallSource` and
  `RuntimeInstallRequestOperation` variants remain hand-written and need a
  separate pass because their public constructors perform string/value-object
  conversion and immutable collection snapshotting.
- Next action: evaluate `RuntimeInstallSource` variants for a narrow Freezed
  conversion slice, starting with configured/local/remote archive source
  constructors and their component archive path snapshots.
- Verification: `cd packages/konyak_cli && dart run build_runner build
  --delete-conflicting-outputs && dart format
  lib/src/domain/runtime/runtime_install_operation_models.dart && dart analyze
  --fatal-infos`, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart --name "runtime install operations"`, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 11:05 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime install plan variants.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed runtime install plans`).
- Purpose: continue replacing hand-written immutable domain model boilerplate
  with Freezed-backed records, focusing on runtime install plan variants after
  evaluating the component-version wrapper.
- Completed work: committed the runtime validation slice; evaluated
  `RuntimeComponentVersions` and deferred it because preserving both
  `const RuntimeComponentVersions.empty()` and current map-based equality would
  either keep hand-written equality or expose the internal `IMap` as the public
  generated field; added focused runtime install plan snapshot coverage;
  converted `RuntimeWineInstallPlan` variants to Freezed-backed variants with
  `copyWith` disabled, preserving existing switch patterns and `IList`
  snapshots for archive component paths.
- Remaining work: `RuntimeComponentVersions` remains intentionally hand-written
  until its public constructor/empty/equality shape can be simplified; the next
  larger candidate is `runtime_install_operation_models.dart`, which still owns
  multiple hand-written install source and operation variants.
- Next action: evaluate `runtime_install_operation_models.dart` for a narrow
  Freezed conversion slice, starting with checksum/signature variants before
  the source/operation constructors.
- Verification: observed the new focused immutability test fail before
  implementation; after implementation, `cd packages/konyak_cli && dart run
  build_runner build --delete-conflicting-outputs && dart format
  lib/src/domain/runtime/runtime_install_plans.dart
  test/domain_immutability_test.dart && dart analyze --fatal-infos`, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart --name
  "runtime install plans expose immutable archive path snapshots"`, `cd
  packages/konyak_cli && dart test test/domain_immutability_test.dart`, `just
  verify-governance`, `just verify-architecture`, `just verify-safety`, `just
  format-check`, `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-29 10:41 JST
- State: `completed`
- Branch: `main`
- Active work: Freezed-backed runtime validation records.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: this commit (`Freezed runtime validation records`).
- Purpose: continue replacing hand-written immutable domain model boilerplate
  with Freezed-backed records, now focusing on runtime validation records,
  platform specs, validation result variants, and executable probe results.
- Completed work: inspected `runtime_validation_models.dart`, validation JSON
  projection governance, platform support const specs, validator switch sites,
  executable probe adapters, and focused validation tests; converted runtime
  validation specs, records, result variants, and executable probe results to
  Freezed-backed models with `copyWith` disabled while preserving const specs,
  switch patterns, RuntimeId conversion for validation records/not-found
  results, immutable check snapshots, and CLI JSON projection ownership;
  regenerated the local ignored `runtime_validation_models.freezed.dart`;
  updated the validator not-found construction to use the public
  `RuntimeValidationResult.runtimeNotFound` factory.
- Remaining work: `RuntimeComponentVersions` still owns hand-written
  equality/hashCode and is the next small model candidate.
- Next action: evaluate `RuntimeComponentVersions` as the next narrow Freezed
  conversion candidate.
- Verification: `cd packages/konyak_cli && dart run build_runner build && dart
  format lib/src/domain/runtime/runtime_validation_models.dart && dart
  analyze --fatal-infos`, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, `just verify-governance`,
  `just verify-architecture`, `just verify-safety`, `just format-check`,
  `just lint`, and `just cli-test` passed.

- Timestamp: 2026-06-28 22:53 JST
- State: `completed`
- Branch: `main`
- Active work: move bottle record JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `70d30cc` (`Move runtime record JSON projections`).
- Purpose: finish the remaining domain JSON projection separation by moving
  `BottleRecord`, `PinnedProgramRecord`, and `BottleRuntimeSettings`
  projections into the bottle metadata serialization boundary used by CLI
  output and repository storage.
- Completed work: committed the runtime record projection slice and inspected
  bottle models, bottle runtime settings, CLI bottle result/list/delete output,
  repository metadata writes, and test metadata helpers; observed
  `just verify-governance` fail before implementation because `BottleRecord`
  still owned JSON projection; added `io/bottle_metadata_json.dart`, updated
  CLI bottle JSON output, repository metadata writes, and test metadata helper
  to use it, removed bottle/domain runtime settings `toJson` methods, and
  updated domain tests to assert domain state instead of JSON shape.
- Remaining work: domain-side `toJson` projections are cleared. Remaining
  `toJson` usage is limited to platform macOS setup DTO output and the I/O-only
  GPTK install record.
- Next action: decide whether to leave platform/I/O DTO local JSON projections
  as acceptable boundary code or add narrow helpers for those too.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused bottle CLI/domain tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:47 JST
- State: `completed`
- Branch: `main`
- Active work: move runtime record JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `e785821` (`Move runtime install progress JSON projection`).
- Purpose: continue separating domain models from CLI serialization by moving
  `RuntimeRecord`, `RuntimeStack`, `RuntimeStackBackend`, and
  `RuntimeStackComponent` projections into the CLI boundary used by
  `list-runtimes --json` and runtime install/update JSON results.
- Completed work: committed the runtime install progress projection slice and
  inspected runtime models, list/install/update runtime JSON call sites, and
  focused runtime CLI contract coverage; observed `just verify-governance`
  fail before implementation because `RuntimeRecord` still owned CLI JSON
  projection; added `cli_runtime_record_json.dart`, updated `list-runtimes`,
  runtime install, and runtime update JSON result call sites, removed runtime
  record/stack/component/backend domain `toJson` methods and JSON-only helper,
  and updated domain tests to assert domain state instead of JSON shape.
- Remaining work: domain `toJson` projections remain in bottle records and
  bottle runtime settings; the I/O-only GPTK install record and platform macOS
  setup DTO still have local JSON projections.
- Next action: continue JSON projection separation with the grouped bottle
  record plus bottle runtime settings slice.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused runtime record CLI/domain tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:42 JST
- State: `completed`
- Branch: `main`
- Active work: move runtime install progress JSON projection out of domain
  models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `b632209` (`Move runtime validation JSON projection`).
- Purpose: continue separating domain models from serialization by moving
  `RuntimeInstallProgress` projection into the JSON progress I/O sink used by
  runtime install `--progress-json` output.
- Completed work: committed the runtime validation projection slice and
  inspected `RuntimeInstallProgress`, `JsonRuntimeInstallProgressSink`, and
  focused progress-json CLI contract coverage; observed
  `just verify-governance` fail before implementation because
  `RuntimeInstallProgress` still owned JSON projection; moved progress JSON
  projection into `runtime_install_progress_io.dart`, updated
  `JsonRuntimeInstallProgressSink`, removed the domain `toJson`, and added
  governance for the progress I/O boundary.
- Remaining work: domain `toJson` projections remain in bottle records, bottle
  runtime settings, runtime records, and the I/O-only GPTK install record.
- Next action: continue JSON projection separation with a larger grouped slice,
  likely bottle records plus bottle runtime settings or runtime records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused runtime install progress-json CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:39 JST
- State: `completed`
- Branch: `main`
- Active work: move runtime validation JSON projection out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `a70a383` (`Move pinned launcher manifest JSON projection`).
- Purpose: continue separating domain models from CLI serialization by moving
  `RuntimeValidationRecord` and `RuntimeValidationCheck` projection into the
  CLI boundary used by `validate-runtime --json`.
- Completed work: committed the pinned launcher manifest projection slice and
  inspected runtime validation models, the `validate-runtime --json` result
  path, and focused CLI contract coverage; observed `just verify-governance`
  fail before implementation because `RuntimeValidationRecord` still owned CLI
  JSON projection; added `cli_runtime_validation_json.dart`, updated
  `validate-runtime --json` output to use the helper, removed the matching
  domain `toJson` methods, and added governance for the runtime validation
  boundary.
- Remaining work: domain `toJson` projections remain in bottle records, bottle
  runtime settings, runtime/runtime package records, and the I/O-only GPTK
  install record.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely runtime install progress or bottle records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused validate-runtime CLI contract test,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:35 JST
- State: `completed`
- Branch: `main`
- Active work: move pinned launcher manifest JSON projection out of domain
  models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `860a0f4` (`Move bottle archive JSON projection`).
- Purpose: continue separating domain models from I/O serialization by moving
  `PinnedProgramLauncherManifest` projection into the launcher manifest I/O
  boundary used by macOS and Linux pinned launcher writers.
- Completed work: committed the bottle archive projection slice and inspected
  pinned launcher manifest model, manifest parser, macOS/Linux writer call
  sites, and focused pin-program CLI contract coverage; observed
  `just verify-governance` fail before implementation because
  `PinnedProgramLauncherManifest` still owned JSON projection; added
  `pinnedProgramLauncherManifestJson` to the launcher manifest I/O helper,
  updated macOS/Linux launcher writers, removed the domain `toJson` and
  model-constant import, and added governance for the pinned launcher manifest
  boundary.
- Remaining work: domain `toJson` projections remain in bottle records, bottle
  runtime settings, runtime/runtime validation/runtime package records, and the
  I/O-only GPTK install record.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely bottle records or runtime validation/package
  records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused pin-program CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:26 JST
- State: `completed`
- Branch: `main`
- Active work: move bottle archive JSON projection out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `a95a20d` (`Move update record JSON projections`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `BottleArchiveRecord` projection into the CLI result boundary used by
  `export-bottle-archive --json`.
- Completed work: committed the update record projection slice, inspected
  bottle archive result output and focused export-bottle-archive CLI contract
  coverage; observed `just verify-governance` fail before implementation
  because `BottleArchiveRecord` still owned CLI JSON projection; moved the
  projection into `cli_bottle_results.dart`, removed the domain `toJson`, and
  added governance for the bottle archive boundary.
- Remaining work: domain `toJson` projections remain in bottle records,
  bottle runtime settings, runtime/runtime validation/runtime package records,
  and pinned launcher manifests.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely pinned launcher manifests or runtime
  validation/package records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused export-bottle-archive CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:21 JST
- State: `completed`
- Branch: `main`
- Active work: move update record JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `66bd7f4` (`Move app settings JSON projections`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `RuntimeUpdateRecord`, `AppUpdateRecord`, and
  `AppUpdateInstallRecord` projections into the CLI serialization boundary used
  by update check/install JSON results.
- Completed work: committed the app settings projection slice, inspected update
  records, app update result output, runtime update result output, and focused
  update CLI contract coverage; observed `just verify-governance` fail before
  implementation because `RuntimeUpdateRecord` still owned CLI JSON
  projection; added `cli_update_json.dart`, moved app/runtime update JSON
  results to that helper, removed the matching domain `toJson` methods and
  private domain JSON helper, updated domain tests to assert domain state
  rather than JSON shape, and added governance for the update boundary.
- Remaining work: domain `toJson` projections remain in bottle,
  runtime/runtime validation/runtime package, and bottle/program mutation
  records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely bottle mutation records or runtime
  validation/package records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused update CLI contract tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:15 JST
- State: `completed`
- Branch: `main`
- Active work: move app settings JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `0df4e9b` (`Move program settings JSON projections`).
- Purpose: continue separating domain models from serialization by moving
  `AppSettingsRecord` and app settings enum JSON mapping into the storage/CLI
  serialization boundary used by get/set-app-settings JSON results and app
  settings storage writes.
- Completed work: committed the program settings projection slice, inspected
  app settings models, CLI app settings result output, storage read/write code,
  and focused app settings CLI contract coverage; observed
  `just verify-governance` fail before implementation because
  `AppSettingsRecord` still owned JSON projection; added
  `io/app_settings_json.dart`, moved app settings projection and external JSON
  parsing to that helper, moved CLI and storage callers to the helper, removed
  domain `toJson` and enum JSON values, updated the domain test to assert the
  value object rather than JSON shape, and added governance for the boundary.
- Remaining work: domain `toJson` projections remain in bottle,
  runtime/update, runtime validation/package, and bottle/program mutation
  records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely update records or bottle mutation records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused app-settings CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 22:05 JST
- State: `completed`
- Branch: `main`
- Active work: move program settings JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `228f203` (`Move graphics backend hint JSON projections`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `ProgramSettingsRecord` and `ProgramLoggingSettingsRecord`
  projections into the serialization boundary used by get/set-program-settings
  JSON results and program settings storage writes.
- Completed work: committed the graphics backend hint projection slice,
  inspected program settings models, CLI program settings result output,
  storage write output, and focused CLI contract coverage; observed
  `just verify-governance` fail before implementation because
  `ProgramSettingsRecord` still owned JSON projection; added
  `io/program_settings_json.dart`, moved CLI program settings results and
  storage writes to that serializer, removed the matching domain `toJson`
  methods, and added governance for both CLI and storage callers.
- Remaining work: many domain `toJson` projections remain, especially bottle,
  runtime/update, app settings, and validation records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely app settings/update records or bottle
  records.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused program-settings CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:58 JST
- State: `completed`
- Branch: `main`
- Active work: move graphics backend hint JSON projections out of domain
  models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `ca7d9a4` (`Move Winetricks catalog JSON projections`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `ProgramGraphicsBackendHints`, signal, and suggestion projections into
  the CLI boundary used by `suggest-graphics-backend --json`.
- Completed work: committed the Winetricks catalog projection slice, inspected
  graphics backend hint models, CLI handler output, and focused CLI contract
  coverage; observed `just verify-governance` fail before implementation
  because `ProgramGraphicsBackendHints` still owned CLI JSON projection; added
  CLI-side hint/signal/suggestion serializers, moved
  `suggest-graphics-backend --json` output to that helper, removed the matching
  domain `toJson` methods and domain JSON host-platform helper, and added
  governance for the graphics backend hint boundary.
- Remaining work: many domain `toJson` projections remain, especially bottle,
  runtime/update, settings, and validation records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely bottle records or program settings.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused suggest-graphics-backend CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:53 JST
- State: `completed`
- Branch: `main`
- Active work: move Winetricks catalog JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `c76e971` (`Move program catalog JSON projections`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `WinetricksVerbRecord` and `WinetricksCategoryRecord` projections into
  the CLI serialization boundary used by `list-winetricks-verbs --json`.
- Completed work: committed the program catalog projection slice, inspected
  the remaining program catalog `toJson` methods, observed
  `just verify-governance` fail before implementation because
  `WinetricksVerbRecord` still owned CLI JSON projection, added CLI-side
  Winetricks verb/category serializers, moved `list-winetricks-verbs --json`
  output to those helpers, removed the matching domain `toJson` methods, and
  tightened governance for the Winetricks catalog boundary.
- Remaining work: many domain `toJson` projections remain, especially bottle,
  runtime/update, settings, validation, and graphics backend hint records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely bottle records or graphics backend hints.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, focused list-winetricks-verbs CLI contract tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:47 JST
- State: `completed`
- Branch: `main`
- Active work: move program catalog JSON projections out of domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `201db96` (`Move wine process termination JSON projection`).
- Purpose: continue separating domain models from CLI JSON serialization by
  moving `ProgramMetadataRecord`, `BottleProgramRecord`, and
  `WineProcessRecord` projections into CLI serialization helpers.
- Completed work: committed the first process-termination projection slice,
  observed `just verify-governance` fail before implementation because
  `BottleProgramRecord` still owned CLI JSON projection, added
  `cli_program_catalog_json.dart`, moved bottle-program and wine-process list
  projections to CLI helpers, removed the matching domain `toJson` methods,
  updated domain tests to assert domain state rather than JSON shape, and added
  governance for the new boundary.
- Remaining work: many domain `toJson` projections remain, especially bottle,
  runtime/update, settings, validation, Winetricks catalog, and graphics
  backend hint records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely Winetricks catalog or bottle record
  projections.
- Verification: observed `just verify-governance` fail before implementation;
  after implementation, `cd packages/konyak_cli && dart analyze
  --fatal-infos`, `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart`, focused list-bottle-programs /
  list-wine-processes CLI contract tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:38 JST
- State: `completed`
- Branch: `main`
- Active work: move `WineProcessTerminationRecord` JSON projection out of
  domain models.
- Related TODO: `docs/todo.md` deferred JSON `toJson` projection separation.
- Latest commit: `240ec3d` (`Type wine process planner boundary`).
- Purpose: begin separating domain models from CLI JSON serialization by
  moving a narrow, recently touched process-termination projection into the
  CLI boundary.
- Completed work: inspected current roadmap/progress state and audited domain
  `toJson` usage; selected `WineProcessTerminationRecord` as the first safe
  slice because CLI process termination tests already cover the external JSON
  contract; added governance that rejects domain-owned termination JSON
  projection and requires CLI-side projection; moved
  `WineProcessTerminationRecord.toJson` into
  `wineProcessTerminationRecordJson` at the CLI boundary.
- Remaining work: many domain `toJson` projections remain, especially bottle,
  program catalog, runtime/update, settings, and validation records.
- Next action: continue JSON projection separation with another narrow
  CLI-covered record group, likely `WineProcessRecord` / `ProgramRecord` or
  bottle read/mutation projections.
- Verification: observed `just verify-governance` fail before implementation
  because `WineProcessTerminationRecord` still owned `toJson`; after
  implementation, `cd packages/konyak_cli && dart analyze --fatal-infos`,
  focused wine-process CLI contract tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, `just lint`, and `git diff --check` passed.

- Timestamp: 2026-06-28 21:28 JST
- State: `completed`
- Branch: `main`
- Active work: type the `ProgramRunPlanner.planWineProcessKill` process-id
  boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `7919c4d` (`Type winetricks verb planner boundary`).
- Purpose: continue planner-boundary tightening by keeping
  `WineProcessId` intact from CLI parsing through winedbg process-kill plan
  construction.
- Completed work: committed the Winetricks verb boundary slice and inspected
  wine-process CLI parsing/handling, `WineProcessTerminationRequest`,
  `terminateWineProcessJsonResult`, `ProgramRunPlanner.planWineProcessKill`,
  and `winedbgAttachProcessId`; added red focused coverage and governance for
  the typed Wine process-id boundary; changed `planWineProcessKill` and
  `winedbgAttachProcessId` to consume `WineProcessId`; preserved typed process
  ids through CLI process termination orchestration until JSON projection.
- Remaining work: broader primitive tightening remains for registry values and
  JSON projection out of domain models.
- Next action: continue the functional-core boundary work with registry value
  objects, or move JSON `toJson` projection once planner entry paths are
  stable.
- Verification: observed `just verify-governance` fail before implementation
  because `ProgramRunPlanner.planWineProcessKill` still exposed
  `String processId`; observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart` fail before implementation because the
  planner and helper still accepted primitive process ids; after
  implementation, `cd packages/konyak_cli && dart analyze --fatal-infos`,
  focused domain immutability tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:20 JST
- State: `completed`
- Branch: `main`
- Active work: type the `ProgramRunPlanner.planWinetricksVerb` verb boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `76765bb` (`Type bottle command planner boundary`).
- Purpose: continue planner-boundary tightening by replacing raw Winetricks
  verb strings with the existing `WinetricksVerbId` domain value object across
  the domain planner and domain request builders.
- Completed work: read the current roadmap/progress state and inspected
  `ProgramRunPlanner.planWinetricksVerb`, Winetricks request builders,
  `isSupportedWinetricksVerb`, CLI run-winetricks handling, and existing
  value-object coverage; added red focused coverage and governance for the
  typed Winetricks verb boundary; changed `planWinetricksVerb`,
  `isSupportedWinetricksVerb`, `linuxWinetricksCommandRequest`, and
  `macosWinetricksCommandRequest` to consume `WinetricksVerbId` or
  `Option<WinetricksVerbId>`; converted CLI run-winetricks input at the
  boundary.
- Remaining work: broader primitive tightening remains for process ids,
  registry values, and JSON projection out of domain models.
- Next action: continue the functional-core boundary work with
  `WineProcessId`, registry value objects, or move JSON `toJson` projection
  once planner entry paths are stable.
- Verification: observed `just verify-governance` fail before implementation
  because `ProgramRunPlanner.planWinetricksVerb` still exposed `String verb`;
  observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart` fail before implementation because the
  planner and support helper still accepted primitive verb values; after
  implementation, `cd packages/konyak_cli && dart analyze --fatal-infos`,
  focused domain immutability tests, `just verify-governance`,
  `just cli-test`, `just verify-architecture`, `just verify-safety`,
  `just format-check`, and `just lint` passed.

- Timestamp: 2026-06-28 21:12 JST
- State: `completed`
- Branch: `main`
- Active work: type the `ProgramRunPlanner.planBottleCommand` command
  boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `6fb4c5f` (`Type program run planner path`).
- Purpose: continue planner-boundary tightening by replacing the raw
  `String command` bottle-command entry point with the existing `BottleCommand`
  domain value object.
- Completed work: committed the program-path planner boundary slice; added red
  governance and domain immutability coverage for typed bottle-command helper
  boundaries; changed `ProgramRunPlanner.planBottleCommand`,
  `_planSupportedBottleCommand`, `supportedBottleCommand`, and
  `wineArgumentsForBottleCommand` to consume `BottleCommand`; converted the CLI
  run-bottle-command handler at the boundary; kept legacy platform/I/O request
  helpers compiling by converting raw command strings internally.
- Remaining work: broader primitive tightening remains for winetricks verbs,
  process ids, registry values, and JSON projection out of domain models.
- Next action: continue the functional-core boundary work with
  `WinetricksVerbId`, `WineProcessId`, registry value objects, or move JSON
  `toJson` projection once planner entry paths are stable.
- Verification: observed `just verify-governance` fail before implementation
  because `ProgramRunPlanner.planBottleCommand` still exposed
  `String command`; observed `cd packages/konyak_cli && dart test
  test/domain_immutability_test.dart` fail before implementation because
  bottle-command helpers still accepted `String`; after implementation,
  `cd packages/konyak_cli && dart analyze --fatal-infos`, focused domain
  immutability tests, `just verify-governance`, `just cli-test`,
  `just verify-architecture`, `just verify-safety`, `just format-check`, and
  `just lint` passed.

- Timestamp: 2026-06-28 21:04 JST
- State: `completed`
- Branch: `main`
- Active work: type the `ProgramRunPlanner.plan` program-path boundary.
- Related TODO: `docs/todo.md` deferred functional-core / OOP-extension
  boundary tightening.
- Latest commit: `08236c1` (`Type program run request boundary`).
- Purpose: continue the request-boundary tightening by replacing the raw
  `String programPath` planner entry point and raw Wine argv projection with
  `ProgramPath` and `ProgramRunArguments` domain values.
- Completed work: read the current roadmap/progress state and inspected
  planner, program argument support, CLI run/pin handlers, and focused domain
  tests; added red coverage for `wineArgumentsForProgramPath(ProgramPath)`
  returning `ProgramRunArguments`; added governance that rejects primitive
  `ProgramRunPlanner.plan` and program argument support signatures; changed
  `ProgramRunPlanner.plan`, `wineArgumentsForProgramPath`, and
  `isSupportedProgramPath` to consume `ProgramPath`; changed Wine argv
  projection to return `ProgramRunArguments`; updated CLI run/pin handlers to
  convert raw external strings at the CLI boundary.
- Remaining work: broader primitive tightening remains for bottle commands,
  winetricks verbs, process ids, registry version values, and other
  non-planner domain-facing request APIs.
- Next action: continue the functional-core boundary work with
  `BottleCommand`, `WinetricksVerbId`, or `WineProcessId`, or move JSON
  `toJson` projection once planner entry paths are stable.
- Verification: observed `just verify-governance` fail before implementation
  because `ProgramRunPlanner.plan` still exposed `String programPath`;
  observed `cd packages/konyak_cli && dart test test/domain_immutability_test.dart`
  fail before implementation because `wineArgumentsForProgramPath` still
  accepted `String`; after implementation, `cd packages/konyak_cli && dart
  analyze --fatal-infos`, focused domain immutability tests,
  `just verify-governance`, `just cli-test`, `just verify-architecture`,
  `just verify-safety`, `just format-check`, and `just lint` passed.

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
