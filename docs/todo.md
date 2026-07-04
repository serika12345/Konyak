# TODO

This list tracks remaining implementation work and deferred decisions. Fully
completed work belongs in commits, tests, release artifacts, and audited
verification output instead of checked-off backlog entries.

## Current Direction

- Konyak owns its runtime, metadata, and distribution decisions.
- arm64 macOS is the first complete runtime target.
- x86_64 Linux is the second complete runtime target.
- macOS uses a Konyak-managed macOS Wine launch plan for Windows program
  execution.
- The macOS runtime layout keeps the loader at
  `Runtimes/macos-wine/bin/wineloader` and launches programs through
  `wineloader start /unix`.
- macOS targets a Konyak-managed component stack produced by
  `serika12345/konyak-macos-runtime`; the macOS runtime stack manifest and
  runtime-owner-produced artifacts remain the source of truth.
- Linux uses the Linux Wine/Proton path and stays Vulkan-oriented.
- Flutter continues to call the backend through a separate CLI process.
- Runtime-specific details stay behind CLI/backend platform services.
- The Flutter app and Dart CLI are the source of truth for application
  behavior.
- Drop live external plist metadata from the supported model. Konyak-owned
  bottle metadata is the source of truth.
- Remove runtime verification masking and prove prefix/addon integrity through
  normal application-owned CLI execution paths.

## Next Tasks

- Capture end-to-end DLSS/MetalFX rendering proof with a redistributable or
  user-provided DLSS-capable Windows program.
  - Use Konyak's public `run-program --json` path, record backend environment,
    selected runtime/component paths, process/log evidence, and Metal HUD or
    equivalent evidence where practical.
  - Do not add proprietary or nonredistributable game payloads to CI.

## Refactoring Milestones

This section tracks the next cleanup pass for compatibility interfaces that were
kept temporarily to land earlier refactoring safely. These gates should remove
one compatibility surface at a time, keep external behavior stable, and stop at
each review gate.

Automatic progression policy:

- `/advance-pr` targets the first unfinished `PR Gate` in this section unless
  the user names another gate.
- `/advance-small` advances the next coherent small milestone inside the
  current `PR Gate`.
- `/review-gate` summarizes the current branch without implementing more work.
- If a required compatibility cleanup is not represented below, add or refine
  the milestone before implementation.

### I1: Compatibility Interface Cleanup

Purpose: remove nullable or primitive compatibility wrappers that were kept to
avoid broad call-site churn during the previous boundary refactoring. Keep the
true external boundaries explicit, but stop preserving internal compatibility
interfaces once call sites can use `Option`, sealed dispatch, or typed value
objects directly.

Small milestones:

- No active I1 small milestones remain.

#### PR Gate: I1-P1 CLI Parser Compatibility Wrappers

status: completed
branch: `task/interface-i1-cli-parser-wrappers`

Completion criteria:

- CLI command-selection call sites use `Option`-returning parser APIs directly
  for at least the runtime and location parser families.
- Nullable parser compatibility wrappers are removed for the converted
  families, or kept only where an external API boundary still requires a
  nullable projection and that reason is documented in code or tests.
- Focused parser or command-selection tests cover missing/incomplete arguments
  without depending on nullable return values.
- Governance is updated so the converted parser families cannot regress to
  nullable compatibility wrappers.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Runtime behavior changes.
- Public CLI JSON schema changes.
- Broad parser rewrites outside the converted families.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P2.

#### PR Gate: I1-P2 CLI Command Dispatch

status: completed
branch: `task/interface-i1-cli-command-dispatch`

Completion criteria:

- Nullable `CliResult?` command handlers and `firstCliResult` dispatch are
  replaced with explicit command-match or command-dispatch variants for the
  converted command groups.
- Missing command matches are modeled as explicit absence or dispatch variants,
  not as `null`.
- Command contract tests cover both matched and unmatched dispatch paths.
- Governance is updated so converted command groups do not reintroduce nullable
  command dispatch.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime installation behavior changes.
- Flutter UI changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P3.

#### PR Gate: I1-P3 Flutter Dialog and Picker Decisions

status: completed
branch: `task/interface-i1-flutter-dialog-decisions`

Completion criteria:

- Konyak-owned dialog, picker, and decision helpers expose explicit variants to
  app code; nullable values remain only at `showDialog`, platform picker, or
  Flutter framework adapter calls.
- Widget tests assert explicit decision or picker variants rather than using
  `null` as the expected application state.
- Any visible behavior remains unchanged; add widget or golden coverage only if
  visible behavior changes.
- Governance is updated so converted app decision helpers do not regress to
  nullable compatibility bridges.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- CLI backend changes.
- Visual redesign.
- Runtime behavior changes.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P4.

#### PR Gate: I1-P4 Flutter JSON DTO Optional Fields

status: completed
branch: `task/interface-i1-flutter-json-dtos`

Completion criteria:

- Flutter CLI JSON parser outputs distinguish invalid, absent, and present
  optional fields with explicit parse/app result models where those fields are
  consumed by application state.
- Nullable `Object?` remains only at JSON decoding and validation boundaries.
- Tests cover absent optional fields and invalid optional field types without
  treating both as the same nullable state unless that is the explicit contract.
- Governance is updated so converted DTOs do not reintroduce nullable app-facing
  summary fields.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime behavior changes.
- Large UI rewrites.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before any new
  milestone is added.

#### PR Gate: I1-P5 Refactoring Governance Allowance Cleanup

status: completed
branch: `task/interface-i1-governance-allowances`

Completion criteria:

- Audit the I1-P1 through I1-P4 governance checks and custom lint allowlists for
  temporary compatibility allowances that only existed to land the earlier
  wrapper removals incrementally.
- Remove stale allowances or replace brittle compatibility-specific string
  checks with stable boundary checks that describe the current app and CLI
  contracts.
- Confirm remaining nullable, primitive, and JSON boundary exceptions are
  limited to framework, platform, parser, or serialization adapters and are
  enforced or documented by governance.
- Update governance tests or script checks so removed compatibility wrappers
  cannot regress without preserving obsolete implementation details as the
  contract.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- App or runtime behavior changes.
- Broad nullable cleanup outside stale governance allowances.
- Starting the next refactoring milestone after I1.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`
- `just konyak-lints-test` if custom lint implementation or lint tests change.

review gate:

- Commit and push the branch, open a draft PR, then stop before adding or
  starting any post-I1 milestone.

### I2: Boundary Hardening and Test Contract Cleanup

Purpose: turn the post-I1 boundary-hardening candidates into scoped refactors
now that the nullable compatibility wrappers are gone. Prefer explicit audits
before conversion, keep external CLI JSON and argv contracts stable, and only
replace primitive values when the invariant is stable enough to be represented
as a value object.

Small milestones:

- [x] I2-S4: Reassess nullable command-selection bridges and
  `ProgramRunPlanner` host-platform, runner-kind, and
  graphics-backend policy structure; split only where the audit shows stable
  responsibilities and reduced complexity.
- [x] I2-S5: Tighten governance and custom lint checks for completed I2
  boundaries without preserving obsolete implementation details as contracts.

#### PR Gate: I2-P1 Primitive Boundary Audit

status: completed
branch: `task/interface-i2-primitive-boundary-audit`

Completion criteria:

- Add an I2 audit document that inventories remaining primitive, nullable, and
  hand-written test-part exceptions across CLI/domain code, Flutter app-facing
  models, custom lint boundary allowlists, and governance checks.
- Classify each finding as an allowed adapter boundary, a candidate for an I2
  code-conversion gate, or an explicitly deferred design decision.
- Refine or add the next I2 PR Gate blocks in `docs/todo.md` when the audit
  identifies a safer order than the current small-milestone list.
- Keep the audit behavior-neutral: no public CLI JSON schema, app behavior,
  runtime behavior, or broad code conversion changes.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime behavior changes.
- Converting primitives or nullable fields before the audit has selected the
  exact boundary.
- Removing all CLI contract test `part` files in the audit PR.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before implementing
  I2 code conversions.

#### PR Gate: I2-P2 CLI Contract Seed Test Part Split

status: completed
branch: `task/interface-i2-cli-contract-seed-tests`

Completion criteria:

- Convert the low-dependency CLI contract `part` files
  `cli_contract_executable.part.dart`, `cli_contract_command_dispatch.part.dart`,
  and `cli_contract_repository_runner.part.dart` into standalone tests or shared
  test helpers.
- Remove the converted `part` directives from `cli_contract_test.dart` without
  changing public CLI JSON, argv, exit-code, app, or runtime behavior.
- Keep equivalent contract assertions for the converted files and preserve the
  remaining high-volume contract part files for later gates.
- Add or update governance so the converted seed files cannot regress to
  hand-written `part` usage.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Converting app/bottle, pinned program, program execution, runtime
  process/update, or runtime install contract parts.
- Public CLI schema or command behavior changes.
- Flutter widget test part cleanup.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before high-volume CLI
  contract test splitting.

#### PR Gate: I2-P3 CLI Contract Family Test Part Split

status: completed
branch: `task/interface-i2-cli-contract-family-tests`

Completion criteria:

- Convert the remaining CLI contract `part` files for app/bottle, pinned
  program, program execution, runtime process/update, and runtime install into
  standalone test files or shared helpers.
- Remove `part` usage from `packages/konyak_cli/test/cli_contract_test.dart`
  entirely while keeping equivalent contract coverage.
- Add or update governance so CLI contract tests cannot reintroduce
  hand-written `part` usage.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Flutter widget test part cleanup.
- Public CLI schema or command behavior changes.
- Domain primitive constructor conversion.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before constructor or
  command-selection boundary conversion.

#### PR Gate: I2-P4 Semantic Constructor Primitive Fronts

status: completed
branch: `task/interface-i2-semantic-constructor-fronts`

Completion criteria:

- Convert selected stable constructor fronts that already validate primitives
  into value objects, starting with settings/runtime fields where call sites are
  controlled and invariants already exist.
- Keep primitive decoding/projection at JSON, argv, persisted metadata, and I/O
  adapter boundaries.
- Add or update focused tests for converted constructor behavior without
  asserting obsolete implementation details.
- Update governance only for the converted constructors.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Runtime manifest/schema type redesign.
- Public CLI JSON schema changes.
- ProgramRunPlanner responsibility splitting.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before nullable
  command-selection or planner policy changes.

#### PR Gate: I2-P5 Command Selection Planner Reassessment

status: completed
branch: `task/interface-i2-command-selection-planner-audit`

Completion criteria:

- Reassess the remaining command-selection bridge around
  `supportedBottleCommand` and `ProgramRunPlanner.planBottleCommand`, and make
  the selected command execution shape explicit before host-specific request
  construction.
- Keep public CLI JSON, argv, exit-code, app, and runtime behavior stable while
  moving command-kind branching out of ad hoc planner string comparisons.
- Add or update focused behavior tests for supported and unsupported bottle
  command selection before implementation.
- Update governance only for the completed command-selection boundary.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime or launcher behavior changes.
- Program path, winetricks verb, process-management, graphics-backend, or
  registry planner redesign.
- Broad nullable cleanup outside the bottle-command selection bridge.
- Advancing I2-S5 governance cleanup outside the converted boundary.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I2-S5
  governance cleanup or any broader planner-policy split.

#### PR Gate: I2-P6 Planner Policy Split Plan

status: completed
branch: `task/interface-i2-planner-policy-split-plan`

Completion criteria:

- Audit the remaining `ProgramRunPlanner` host-platform switches,
  runner-kind selection, macOS version policy, and graphics-backend policy
  call sites after the completed bottle-command selection split.
- Decide whether the next safe implementation gate should split host request
  families, runner-kind policy, graphics-backend policy, or leave the remaining
  planner structure intact until a more concrete behavioral need appears.
- Add the next implementation PR Gate only when the audit identifies a stable
  responsibility boundary that reduces complexity without changing public CLI
  JSON, argv, exit-code, app, or runtime behavior.
- Record explicitly deferred planner-policy decisions when a split would only
  move conditionals without improving the boundary.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime, launcher, or Wine behavior changes.
- Implementing the host request-family, runner-kind, or graphics-backend split
  before the audit has selected the exact boundary.
- Broad I2-S5 governance tightening outside planner-policy gate definition.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before implementation
  of any further planner-policy split.

#### PR Gate: I2-P7 Registry Planner Platform Policy

status: completed
branch: `task/interface-i2-registry-platform-policy`

Completion criteria:

- Replace the raw `includeMacDriverSettings` boolean bridge between
  `ProgramRunPlanner` and registry plan helpers with an explicit registry
  planning policy that carries the macOS/Linux platform decision.
- Keep generated registry updates, registry queries, argv, public CLI JSON,
  exit codes, app behavior, runtime behavior, and Wine execution paths stable.
- Add or update focused tests proving macOS includes Wine Mac Driver registry
  values and Linux excludes them without depending on implementation details.
- Update governance only for the completed registry planner policy boundary.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime, launcher, Wine, graphics-backend, or request-builder behavior
  changes.
- Host request-family extraction outside registry planning.
- Runner-kind enum redesign or runner-kind JSON contract changes.
- Unifying domain and platform request-builder files.
- Broad I2-S5 governance tightening outside the converted boundary.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before broader
  host request-family, runner-kind, graphics-backend, or I2-S5 governance
  cleanup.

#### PR Gate: I2-P8 Governance and Custom Lint Tightening

status: completed
branch: `task/interface-i2-governance-tightening`

Completion criteria:

- Audit governance and custom lint checks added or updated during I2-P1 through
  I2-P7 for stale allowances, obsolete branch/progress references, and checks
  that preserve implementation details instead of stable boundary outcomes.
- Replace stale or overly implementation-specific governance checks with
  behavior-neutral boundary checks for the completed I2 conversions, including
  CLI contract test part removal, semantic constructor value-object fronts,
  command-selection dispatch, and registry planning policy.
- Tighten custom lint boundary allowlists only for paths already converted by
  completed I1/I2 gates and covered by lint fixtures or focused tests.
- Keep external CLI JSON, argv, exit codes, Flutter framework adapter
  nullability, runtime behavior, and Wine execution paths stable.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- New nullable, primitive, constructor, command-selection, request-builder,
  runner-kind, graphics-backend, runtime, or Flutter UI boundary conversions.
- Public CLI JSON schema changes.
- Runtime, launcher, Wine, app behavior, or visible UI changes.
- Narrowing broad Flutter framework adapter nullability allowances that are not
  already covered by explicit app-facing decision models.
- Adding new post-I2 implementation milestones before this governance cleanup
  is reviewed.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`
- `just konyak-lints-test` if custom lint implementation, lint fixtures, or
  lint tests change.

review gate:

- Commit and push the branch, open a draft PR, then stop before implementation
  work beyond this governance cleanup.

### I3: Mechanical Type-Safety Hardening

Purpose: improve type safety through mechanical, behavior-preserving
conversions of stable primitive discriminants and constructor fronts into
explicit enums, catalogs, or value objects. Keep external CLI JSON, argv,
persisted metadata, runtime manifests, and visible app behavior stable. Do not
convert runtime-owner manifest strings unless the conversion has a clear
adapter boundary back to the public schema value.

Medium milestones, one PR unit each:

- [x] I3-M1: Inventory remaining mechanically convertible primitive and enum
  fronts, classify them as PR-sized conversion gates, adapter-boundary
  primitives, or deferred design decisions.
- [x] I3-M2: Replace stable `RunnerKind` string literal construction with a
  typed runner-kind catalog or enum-backed factory while preserving existing
  public JSON string values.
- [x] I3-M3: Convert stable runtime platform-definition constructor fronts for
  ids, names, roles, architecture, runner kind, backend ids, and component ids
  into value objects where the current constructors already validate or project
  to those values.
- [x] I3-M4: Convert stable runtime model and source-manifest constructor
  fronts to typed value-object inputs where they are Konyak-owned domain
  values, while keeping JSON and manifest parsing as adapter boundaries.
- [ ] I3-M5: Convert macOS and Linux runtime install request wrapper fronts
  from nullable archive/source strings into typed optional runtime install
  value-object inputs while leaving CLI/update JSON parsing as the adapter
  boundary.
- [ ] I3-M6: Convert macOS major-version capability plumbing from `Option<int>`
  to an explicit value object or capability input if the I3 inventory confirms
  the conversion is mechanical and behavior-neutral.
- [ ] I3-M7: Tighten governance and custom lint checks so completed I3
  conversions cannot regress to ad hoc primitive construction, without
  preserving temporary implementation details as contracts.

#### PR Gate: I3-P1 Type-Safety Inventory and Gate Order

status: completed
branch: `task/type-safety-i3-inventory`

Completion criteria:

- Add an I3 audit document that inventories remaining primitive, nullable, and
  string-discriminant fronts across CLI/domain code, Flutter app-facing models,
  runtime platform definitions, request builders, custom lint allowlists, and
  governance checks.
- Classify each finding as a mechanical conversion PR, an allowed adapter
  boundary, or an explicitly deferred design decision.
- Refine the I3-P2 through I3-P7 gate order if the audit identifies a safer
  mechanical sequence than the initial plan.
- Keep the audit behavior-neutral: no public CLI JSON schema, app behavior,
  runtime behavior, Wine execution path, or broad code conversion changes.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Implementing enum/value-object conversions before the audit selects the exact
  boundary.
- Public CLI JSON schema changes.
- Runtime, launcher, Wine, app, or visible UI behavior changes.
- Broad linter allowlist narrowing.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before implementing
  I3-P2.

#### PR Gate: I3-P2 Runner Kind Typed Catalog

status: completed
branch: `task/type-safety-i3-runner-kind-catalog`

Completion criteria:

- Introduce a typed runner-kind catalog, enum, or enum-backed factory for the
  stable runner kinds used by program request builders.
- Replace direct `RunnerKind('<literal>')` construction in domain, platform,
  I/O request builders, and focused tests with the typed catalog or enum-backed
  factory where the runner kind is one of the stable known values.
- Keep `RunnerKind.value`, public CLI JSON `runnerKind` strings, argv, exit
  codes, runtime behavior, and Wine execution paths unchanged.
- Add or update focused tests proving the typed catalog projects to the same
  public runner-kind strings for Linux, macOS, registry, terminal, winetricks,
  wineserver, and winedbg requests.
- Update governance only for the completed runner-kind construction boundary.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Renaming existing runner-kind string values.
- Changing process launch, request-builder argv, runtime, Wine, or app
  behavior.
- Converting runtime manifest `runnerKind` fields before I3-P2 selects that
  boundary.
- Host request-family extraction or request-builder unification.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I3-P3.

#### PR Gate: I3-P3 Runtime Platform Definition Type Fronts

status: completed
branch: `task/type-safety-i3-runtime-platform-definitions`

Completion criteria:

- Convert stable `RuntimePlatformSpec`, `RuntimeStackComponentDefinition`, and
  `RuntimeBackendDefinition` constructor fronts from primitive strings/lists to
  existing value objects for runtime ids, names, roles, architecture,
  runner-kind, component ids, backend ids, archive paths, and environment keys
  where those values are Konyak-owned definitions.
- Keep JSON parsing and runtime-owner manifest decoding at explicit adapter
  boundaries, projecting typed values back to the same public schema strings.
- Add or update focused domain and CLI contract tests proving list-runtimes,
  runtime validation, runtime install planning, and source manifest behavior
  stay schema-compatible.
- Update governance only for the converted runtime platform-definition
  constructor fronts.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Changing runtime owner manifest schemas.
- Changing public CLI JSON schema or persisted metadata.
- Broad runtime package/install behavior changes.
- Converting process diagnostic strings, human-readable messages, or fields
  that do not carry stable identity/invariants.
- Linux runtime packaging-owner build/check hardening.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I3-P4.

#### PR Gate: I3-P4 Runtime Model and Source Manifest Type Fronts

status: completed
branch: `task/type-safety-i3-runtime-model-fronts`

Completion criteria:

- Convert stable `RuntimeDefinition`, `RuntimeRecord`, `RuntimeStack`,
  `RuntimeStackComponent`, `RuntimeStackBackend`, `RuntimeSourceManifest`, and
  `RuntimeSourceComponent` constructor fronts from primitive strings/lists to
  existing value objects where the values are Konyak-owned domain state.
- Preserve JSON parsing, persisted metadata, runtime-owner manifest decoding,
  and CLI projection as explicit primitive adapter boundaries.
- Keep public CLI JSON, persisted metadata, runtime manifest schemas, runtime
  behavior, and Wine execution paths unchanged.
- Add or update focused domain and CLI contract tests for list-runtimes,
  runtime update, runtime install planning, runtime source manifest lookup, and
  source archive planning where converted constructors participate.
- Update governance only for the converted runtime model constructor fronts.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Changing runtime owner manifest schemas.
- Changing public CLI JSON schema or persisted metadata.
- Converting human-readable diagnostic messages, process stdout/stderr, or
  process exit codes.
- Runtime platform-definition constructor conversion already owned by I3-P3.
- Linux runtime packaging-owner build/check hardening.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I3-P5.

#### PR Gate: I3-P5 Runtime Install Request Type Fronts

status: planned
branch: `task/type-safety-i3-runtime-install-requests`

Completion criteria:

- Convert `MacosWineInstallRequest` and `LinuxWineInstallRequest` constructor
  fronts from nullable archive/source strings and primitive component archive
  path iterables to typed `Option<RuntimeArchivePath>`,
  `Option<RuntimeArchiveUrl>`, `Option<RuntimeArchiveChecksumValue>`,
  `Option<RuntimeSourceManifestUrl>`,
  `Option<RuntimeSourceManifestSignatureUrl>`, and iterable
  `RuntimeArchivePath` inputs.
- Preserve CLI parser, update JSON, persisted metadata, runtime manifest,
  runtime install planning, runtime behavior, and Wine execution path
  behavior.
- Keep public convenience projection getters returning existing primitive
  strings where CLI JSON or progress output requires the public schema shape.
- Add or update focused CLI/runtime install tests proving full install, repair,
  component install, and update install requests produce the same typed
  `RuntimeInstallRequestOperation` and public JSON/progress values.
- Update governance only for the converted runtime install request wrapper
  fronts.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Changing runtime install operation semantics.
- Changing public CLI JSON schema, update metadata, runtime source manifests,
  runtime behavior, or Wine execution paths.
- Runtime platform-definition constructor conversion already owned by I3-P3.
- Runtime model and source-manifest constructor conversion already owned by
  I3-P4.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I3-P6.

#### PR Gate: I3-P6 macOS Version Capability Type Front

status: planned
branch: `task/type-safety-i3-macos-version-capability`

Completion criteria:

- Replace `Option<int>` macOS major-version plumbing in `ProgramRunPlanner` and
  macOS request/terminal helpers with an explicit value object or capability
  input, only if I3-P1 confirms the conversion is mechanical and
  behavior-neutral.
- Keep D3DMetal DLSS/MetalFX environment selection, terminal setup, CLI JSON,
  argv, runtime behavior, Wine execution paths, and app behavior unchanged.
- Add or update focused tests proving macOS version presence/absence and
  version thresholds preserve the same request environment decisions.
- Update governance only for the converted macOS version/capability boundary.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Introducing a broad macOS capability service.
- Changing D3DMetal, DXMT, DXVK, Metal HUD/capture, or runtime component
  policy.
- Runtime request-family extraction or platform request-builder unification.
- Converting unrelated process ids, exit codes, PE offsets, or diagnostic
  integers.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I3-P7.

#### PR Gate: I3-P7 Type-Safety Governance and Lint Guardrails

status: planned
branch: `task/type-safety-i3-governance`

Completion criteria:

- Audit I3-P1 through I3-P6 governance checks and custom lint allowlists for
  stale allowances or brittle implementation-detail assertions.
- Add narrow governance or custom lint checks that prevent reintroducing ad hoc
  runner-kind literals, primitive runtime constructor fronts, and primitive
  runtime install request or macOS version capability plumbing in converted
  paths.
- Keep remaining adapter-boundary primitives documented where they represent
  public JSON, persisted metadata, runtime-owner manifests, or process
  diagnostics.
- Remove completed I3 items from active progress while leaving any genuinely
  deferred type-safety candidates explicit in `docs/todo.md`.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- New enum/value-object conversions beyond I3-P2 through I3-P6.
- Public CLI JSON, persisted metadata, runtime manifest, runtime behavior, or
  visible UI changes.
- Broad linter allowlist narrowing outside converted paths.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`
- `just konyak-lints-test` if custom lint implementation, fixtures, or tests
  change.

review gate:

- Commit and push the branch, open a draft PR, then stop before adding further
  type-safety conversion gates.

## Deferred

- Linux ARM64 Windows execution research.
- Linux executable thumbnails for sandboxed file managers.
  - Do not make the AppImage or normal app startup mutate `/nix/store` or
    create Nix GC roots on the user's behalf.
  - Treat GNOME/Nautilus thumbnailer sandboxing as normal behavior, not as a
    user configuration problem. The thumbnailer executable must be visible from
    the file manager's sandbox when on-demand thumbnails are supported.
  - Keep the existing Windows executable file association and launcher
    registration separate from thumbnail generation.
  - Design a NixOS integration path, such as a Nix package, Home Manager
    module, or NixOS module, that installs a sandbox-visible Konyak thumbnail
    helper and registers the Freedesktop `.thumbnailer` entry.
  - Consider an app-owned pre-generation path that writes Freedesktop thumbnail
    cache PNGs for executables Konyak has already inspected, while documenting
    that this is not a substitute for arbitrary Nautilus on-demand thumbnails.
  - Preserve the dynamic finding that home-directory AppImage/wrapper
    thumbnailers are not visible to GNOME's `bwrap` thumbnailer sandbox on the
    tested NixOS/Nautilus setup.
- Add E2E tests.
  - Decide the target level before implementation: Flutter integration tests
    with a fake CLI, real CLI tests against temporary directories, or a small
    full-stack Flutter plus real CLI smoke suite.
  - Keep the E2E target separate from the default fast verification gate until
    its runtime cost and flake rate are known.
- Linux runtime packaging-owner build/check hardening.
  - Add submodule-side workflows that build and verify Linux runtime components
    from pinned source recipes before the next runtime version bump.
  - Mirror or explicitly verify the Wine archive when Konyak stops referencing
    the upstream Kron4ek release asset.
  - Keep the parent repository consuming only runtime-owner-produced complete
    source manifests and archives.
