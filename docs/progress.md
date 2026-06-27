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
