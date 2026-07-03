# I2 Primitive Boundary Audit

This audit records the remaining primitive, nullable, and hand-written test
part exceptions after I1. It is behavior-neutral: it does not change public CLI
JSON, argv contracts, app behavior, runtime behavior, or runtime packaging.

## Inventory Basis

- Production hand-written `part` usage is blocked by
  `scripts/verify_governance.py` and `konyak_no_handwritten_part`; CLI contract
  tests are now standalone libraries, and the remaining intentional `part`
  usage is limited to lint fixtures.
- Nullable values in `packages/konyak_cli/lib/src/domain` were not found by the
  I2 inventory search outside generated files. Remaining nullable flow is in
  CLI, I/O, platform, Flutter CLI parser, and Flutter framework adapter paths.
- Primitive domain-facing values remain mostly as constructor compatibility
  fronts that immediately validate into value objects, diagnostic strings,
  process result values, and runtime manifest/schema definitions.

## Hand-Written Test Parts

| Exposure | Category | I2 action |
| --- | --- | --- |
| `packages/konyak_cli/test/cli_contract_test.dart` previously owned a large hand-written contract-test part library. | Completed I2 boundary. CLI contract tests are now standalone libraries with shared helpers, and no `*.part.dart` files remain under `packages/konyak_cli/test`. | Keep the generic governance check that blocks any future CLI test part files or part-library registration helpers, rather than preserving the old file-name list as the contract. |
| `apps/konyak/test/widget_test.dart` owns seven hand-written widget test `part` files. | Deferred design decision. Widget test setup is a separate Flutter test architecture concern and is not the first risk to I2 CLI/domain boundary hardening. | Do not change during CLI contract test split. Reassess only after CLI contract parts are removed or a Flutter test architecture gate is added. |
| `tools/konyak_lints/test/fixtures/invalid/**` contains hand-written `part` and `part of` violations. | Allowed test fixture boundary. The files intentionally exercise lint diagnostics. | Keep. Governance and custom lint tests should continue to distinguish invalid fixtures from production/test harness debt. |

## Nullable Boundaries

| Exposure | Category | I2 action |
| --- | --- | --- |
| CLI parser helpers such as `packages/konyak_cli/lib/src/cli/cli_parsers.dart`, `cli_program_run_parsers.dart`, `cli_program_mutation_parsers.dart`, and remaining parser families use `String?`, `Object?`, `return null`, `Option.fromNullable`, and nullable projection helpers around `ArgResults` and JSON decoding. | Mixed: allowed adapter boundary at `ArgResults` and decoded JSON, candidate where `Option` is converted back to nullable only to fit command-selection APIs. | Keep raw external reads at the CLI boundary. After the test part split, remove the remaining nullable parser bridge helpers family by family when command tests can be isolated. |
| Converted command handler selection for runtime and location commands now returns explicit `CliCommandMatch` variants instead of nullable command results. | Completed I2 boundary for the converted command groups. This is internal command dispatch absence, not an external nullable payload. | Keep focused governance and `konyak_no_nullable_cli_command_handler` coverage so converted command handlers cannot regress to nullable `CliResult` dispatch while unconverted command groups remain out of scope. |
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
| `tools/konyak_lints/lib/konyak_lints.dart` contains nullable and hand-written part lint rules plus broad external-boundary allowlists. | Mixed. The broad boundary allowlists remain for real adapter paths, while completed command-dispatch handlers now have focused custom lint coverage. | Keep broad adapter allowances until a concrete path is converted and covered; add narrow rules only for completed boundaries, as done for `konyak_no_nullable_cli_command_handler`. |
| `tools/konyak_lints/test/fixtures/invalid` intentionally keeps invalid nullable and part examples. | Allowed lint fixture boundary. | Keep. These fixtures should continue to prove the rules fire. |

## Next Gate Order

1. I2-P2 and I2-P3 completed the CLI contract test part split.
2. I2-P4 completed the selected semantic constructor value-object fronts.
3. I2-P5 completed the runtime/location command-selection dispatch boundary.
4. I2-P6 audited remaining planner-policy split candidates and selected only
   the registry policy as the next stable implementation boundary.
5. I2-P7 completed registry planner platform policy.
6. I2-P8 tightens governance and custom lint checks only for completed I2
   boundaries, leaving broader adapter allowances deferred until their owning
   paths are converted.
