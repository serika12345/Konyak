# I2 Primitive Boundary Audit

This audit records the remaining primitive, nullable, and hand-written test
part exceptions after I1. It is behavior-neutral: it does not change public CLI
JSON, argv contracts, app behavior, runtime behavior, or runtime packaging.

## Inventory Basis

- Production hand-written `part` usage is already blocked by
  `scripts/verify_governance.py` and `konyak_no_handwritten_part`; remaining
  `part` usage is in tests and lint fixtures.
- Nullable values in `packages/konyak_cli/lib/src/domain` were not found by the
  I2 inventory search outside generated files. Remaining nullable flow is in
  CLI, I/O, platform, Flutter CLI parser, and Flutter framework adapter paths.
- Primitive domain-facing values remain mostly as constructor compatibility
  fronts that immediately validate into value objects, diagnostic strings,
  process result values, and runtime manifest/schema definitions.

## Hand-Written Test Parts

| Exposure | Category | I2 action |
| --- | --- | --- |
| `packages/konyak_cli/test/cli_contract_test.dart` owns eight hand-written `part` files: `cli_contract_app_bottle.part.dart`, `cli_contract_pinned_program.part.dart`, `cli_contract_program_execution.part.dart`, `cli_contract_repository_runner.part.dart`, `cli_contract_runtime_process_update.part.dart`, `cli_contract_runtime_install.part.dart`, `cli_contract_executable.part.dart`, and `cli_contract_command_dispatch.part.dart`. | Candidate for I2 code-conversion gate. These are tests, not production behavior, but the large shared library makes contract coverage hard to move or review independently. | Split in two gates. First convert the low-dependency seed files, then convert the high-volume app/runtime/program families after the shared helper shape is proven. |
| `apps/konyak/test/widget_test.dart` owns seven hand-written widget test `part` files. | Deferred design decision. Widget test setup is a separate Flutter test architecture concern and is not the first risk to I2 CLI/domain boundary hardening. | Do not change during CLI contract test split. Reassess only after CLI contract parts are removed or a Flutter test architecture gate is added. |
| `tools/konyak_lints/test/fixtures/invalid/**` contains hand-written `part` and `part of` violations. | Allowed test fixture boundary. The files intentionally exercise lint diagnostics. | Keep. Governance and custom lint tests should continue to distinguish invalid fixtures from production/test harness debt. |

## Nullable Boundaries

| Exposure | Category | I2 action |
| --- | --- | --- |
| CLI parser helpers such as `packages/konyak_cli/lib/src/cli/cli_parsers.dart`, `cli_program_run_parsers.dart`, `cli_program_mutation_parsers.dart`, and remaining parser families use `String?`, `Object?`, `return null`, `Option.fromNullable`, and nullable projection helpers around `ArgResults` and JSON decoding. | Mixed: allowed adapter boundary at `ArgResults` and decoded JSON, candidate where `Option` is converted back to nullable only to fit command-selection APIs. | Keep raw external reads at the CLI boundary. After the test part split, remove the remaining nullable parser bridge helpers family by family when command tests can be isolated. |
| Command handler selection still has nullable result fronts in files such as `cli_app_handlers.dart`, `cli_bottle_read_handlers.dart`, `cli_bottle_mutation_handlers.dart`, `cli_program_run_handlers.dart`, and `cli_wine_process_handlers.dart`. | Candidate for I2 code-conversion gate. This is internal command dispatch absence, not an external nullable payload. | Revisit after the CLI contract test harness is split, so each command group can move to explicit match variants with focused tests. |
| CLI JSON projection files under `packages/konyak_cli/lib/src/cli`, including runtime, program, update, bottle, and validation JSON helpers, use `Map<String, Object?>` and optional field projection. | Allowed adapter boundary. Public CLI JSON requires nullable JSON field support and stable schema projection. | Keep. Future governance can require projection to stay under CLI/I/O paths rather than eliminating nullable JSON maps. |
| Flutter CLI contract parsers under `apps/konyak/lib/src/cli` use `Object?`, `Map<String, Object?>`, and optional string checks while validating `jsonDecode` payloads. | Allowed adapter boundary. This is the app side of external CLI JSON validation. | Keep nullable decoding local to parser functions. Do not pass nullable absence into app state unless the explicit app-facing model says the external field is optional. |
| Flutter UI/framework files use nullable callbacks, widget children, dialog returns, and framework values such as optional `BuildContext`-driven actions. | Allowed adapter boundary at the Flutter framework line. | Keep. View-model and app-decision helpers should remain explicit variants when values leave the widget/framework adapter. |
| Custom lint `_isExternalNullBoundaryPath` currently allows broad CLI, I/O, platform, home-loader, app, DTO, and selected app widget paths. | Mixed: allowed while I2 conversion is incomplete, candidate for later tightening. | Tighten only after the specific converted path has tests and governance. Do not narrow the broad Flutter app allowance before the remaining framework adapter cases are separated. |

## Primitive Domain Values

| Exposure | Category | I2 action |
| --- | --- | --- |
| Constructor fronts such as `AppSettingsRecord(defaultBottlePath: String)`, `BottleRuntimeSettings(enhancedSync: String, dxvkHud: String, buildVersion: int, dpiScaling: int)`, and `ProgramSettingsRecord(locale: String, arguments: String)` validate into existing value objects. | Candidate for I2 code-conversion gate. The invariants are stable and value objects already exist, but constructor compatibility reduces call-site churn. | Convert in a dedicated gate after CLI test harness cleanup. Keep JSON and persisted metadata decoding as the primitive adapter boundary. |
| `RuntimeValidationRecord(runtimeId: String)` validates to `RuntimeId`, while `RuntimeExecutableProbeResult` and process run results expose exit codes/stdout/stderr strings. | Mixed. `RuntimeValidationRecord` is a conversion candidate; process outputs are allowed adapter diagnostics. | Convert runtime IDs where stable. Keep process outputs as primitive diagnostics unless structured recovery or localization requires richer result types. |
| `RuntimePlatformSpec`, `RuntimeStackComponentDefinition`, and `RuntimeBackendDefinition` use primitive ids, names, roles, architecture, component paths, archive names, and environment keys. | Deferred design decision. These mirror runtime-owner manifests and schema definitions rather than normal domain state. | Do not convert opportunistically. Add a runtime manifest typing gate only if manifest editing, validation, or source-of-truth ownership needs stronger domain invariants. |
| `ProgramRunPlanner` stores `KonyakHostPlatform`, `HostEnvironment`, and `Option<int> macosMajorVersion`, then branches across Linux/macOS runner policy, terminal policy, registry policy, winetricks policy, and runtime settings policy. | Deferred design decision. Existing typed request/value-object boundaries are protected, but responsibility split may become useful after parser/constructor compatibility fronts are cleaned. | Reassess in a later planner policy gate. Split only if the audit-backed cleanup reduces responsibility mixing without changing public execution paths. |
| Diagnostic messages in sealed results and failures remain plain `String`. | Allowed boundary for now. These strings are human-facing diagnostics, not branch-driving identity. | Keep until localization, message codes, or structured recovery becomes a product requirement. |
| Boolean settings flags such as runtime toggles and update preferences remain `bool`. | Allowed domain state. The field name carries the invariant and a two-state value object would add little safety. | Keep unless a setting grows beyond binary state or needs platform-specific capability modeling. |

## Governance And Lint State

| Exposure | Category | I2 action |
| --- | --- | --- |
| `scripts/verify_governance.py` already blocks production hand-written parts and many typed CLI/domain boundaries. | Allowed guardrail. | Extend governance only to require this audit and the next I2 gates. Add narrower test-part regression checks in the gates that actually split the tests. |
| `tools/konyak_lints/lib/konyak_lints.dart` contains nullable and hand-written part lint rules plus broad external-boundary allowlists. | Candidate for later tightening, not for the audit PR. | Update allowlists only after a concrete path has been converted and covered. Avoid preserving obsolete implementation details as lint contracts. |
| `tools/konyak_lints/test/fixtures/invalid` intentionally keeps invalid nullable and part examples. | Allowed lint fixture boundary. | Keep. These fixtures should continue to prove the rules fire. |

## Next Gate Order

1. Split low-dependency CLI contract test parts first. This proves the shared
   helper shape with small files before touching the large runtime/program
   suites.
2. Split the high-volume CLI contract test families next. This removes the
   main hand-written test-part exception and gives future boundary conversions
   smaller test entry points.
3. Convert stable constructor compatibility fronts that already validate into
   value objects.
4. Revisit nullable command-selection bridges once command-group tests are no
   longer tied to one large test library.
5. Tighten custom lint/governance allowlists only for paths that have already
   been converted.
