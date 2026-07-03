# I3 Type-Safety Inventory

This audit records the remaining mechanically convertible type-safety fronts
after I2. It is behavior-neutral: it does not change public CLI JSON, argv
contracts, persisted metadata, runtime manifests, app behavior, runtime
behavior, or Wine execution paths.

## Inventory Basis

- Existing domain value objects already cover the main runtime and program
  identities: `RunnerKind`, `RuntimeId`, `RuntimeName`,
  `RuntimePlatformName`, `RuntimeArchitecture`, `RuntimeStackId`,
  `RuntimeCompatibilityTarget`, `RuntimeComponentId`, `RuntimeBackendId`,
  `RuntimeRole`, `RuntimeRelativePath`, `RuntimeArchivePath`,
  `RuntimeArchiveUrl`, `RuntimeVersionUrl`, `RuntimeSourceManifestUrl`,
  `RuntimeSourceComponentId`, and `RuntimeSourceComponentVersion`.
- Production request builders still construct stable runner-kind values with
  direct `RunnerKind('<literal>')` calls in domain, platform, and I/O request
  files. The public `runnerKind` JSON strings remain part of the CLI contract.
- Runtime platform definition data is concentrated in
  `RuntimePlatformSpec`, `RuntimeStackComponentDefinition`, and
  `RuntimeBackendDefinition`. These are `const` catalog models that still
  expose primitive strings and string-list paths.
- Runtime record, stack, and source-manifest models already store typed
  `_validated` fields internally, but their public factories still accept
  primitive constructor fronts for compatibility.
- macOS and Linux runtime install request wrappers still expose nullable
  archive/source string parameters before immediately converting them into the
  typed `RuntimeInstallRequestOperation` model.
- `ProgramRunPlanner` and the macOS request builders carry
  `Option<int> macosMajorVersion` as a feature capability input for
  D3DMetal DLSS/MetalFX environment selection.
- Flutter app-facing summaries and CLI contract parsers intentionally keep
  primitive strings and nullable JSON fields at the app side of the external
  CLI JSON adapter boundary.
- Existing governance and custom lint checks guard I1/I2 conversions, but they
  do not yet block regression from completed I3 runner-kind, runtime
  constructor-front, or install-request-front conversions.

## Mechanical Conversion PRs

| Exposure | Evidence | I3 action |
| --- | --- | --- |
| Stable runner-kind literals are constructed directly with `RunnerKind('<literal>')`. | `packages/konyak_cli/lib/src/domain/program/program_run_linux_requests.dart`, `program_run_macos_requests.dart`, `program_run_terminal_requests.dart`, `packages/konyak_cli/lib/src/platform/linux/linux_program_run_requests.dart`, `packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart`, and `packages/konyak_cli/lib/src/io/wine_run_requests.dart`. | I3-P2. Add a typed runner-kind catalog or enum-backed factory for stable Konyak-owned values, then replace direct literal construction in request builders and focused tests. Preserve `RunnerKind.value` and public `runnerKind` JSON strings. |
| Runtime platform definition constructors expose primitive ids, names, roles, architecture, runner kind, component ids, and relative paths. | `packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart` and the Linux/macOS catalogs in `runtime_platform_support.dart`. | I3-P3. Convert the catalog-facing constructors and fields to existing value objects where possible. Handle the current `const` catalog shape deliberately, either by adding const-friendly typed catalog values or by making the runtime platform catalog non-const without changing behavior. |
| `RuntimeDefinition`, runtime record, stack, component, backend, and source-manifest public factories accept primitive strings/lists before validating to typed internals. | `packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart`, `packages/konyak_cli/lib/src/io/runtime_platform_records.dart`, `packages/konyak_cli/lib/src/io/runtime_source_manifest_support.dart`, and runtime contract tests. | I3-P4. Move Konyak-owned constructor fronts to typed value-object inputs. Keep JSON and runtime source-manifest parsing as explicit adapter boundaries that validate strings before entering domain state. |
| `MacosWineInstallRequest` and `LinuxWineInstallRequest` expose nullable archive/source strings and primitive component archive paths before converting to typed runtime install operations. | `packages/konyak_cli/lib/src/platform/macos/macos_wine_install_requests.dart` and `packages/konyak_cli/lib/src/platform/linux/linux_wine_install_requests.dart`. | I3-P5. Replace nullable string fronts with typed `Option<RuntimeArchivePath>`, `Option<RuntimeArchiveUrl>`, `Option<RuntimeArchiveChecksumValue>`, `Option<RuntimeSourceManifestUrl>`, `Option<RuntimeSourceManifestSignatureUrl>`, and iterable `RuntimeArchivePath` inputs. Leave CLI/update JSON parsing as the adapter boundary. |
| macOS major-version plumbing is represented as `Option<int>` through planner and request-builder APIs. | `packages/konyak_cli/lib/src/domain/program/program_runner.dart`, `program_run_macos_requests.dart`, `program_run_terminal_requests.dart`, `packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart`, `platform_terminal_commands.dart`, and `packages/konyak_cli/lib/src/io/wine_run_requests.dart`. | I3-P6. Replace the raw integer option with an explicit macOS version or capability input if the implementation can remain behavior-neutral. The capability must preserve the current default of "unknown means DLSS/MetalFX disabled". |
| Governance and lint checks do not yet name completed I3 conversion boundaries. | `scripts/verify_governance.py` and `tools/konyak_lints/lib/konyak_lints.dart`. | I3-P7. Add narrow guardrails only after I3-P2 through I3-P6 complete, so the checks protect stable outcomes instead of temporary implementation details. |

## Allowed Adapter Boundaries

| Exposure | Category | I3 decision |
| --- | --- | --- |
| CLI JSON rendering and parsing uses `Map<String, Object?>`, `Object?`, optional JSON fields, and public schema strings. | Allowed adapter boundary. | Keep under `packages/konyak_cli/lib/src/cli`, `packages/konyak_cli/lib/src/io`, and `apps/konyak/lib/src/cli`. I3 conversions must project back to the same public strings and nullable JSON fields where the schema requires them. |
| Runtime source manifests arrive as JSON strings for ids, URLs, versions, and checksums. | Allowed external payload boundary. | Keep raw reads in `runtime_source_manifest_support.dart`; validate into value objects before constructing domain source-manifest state during I3-P4. |
| Flutter `ProgramRunSummary`, `RuntimeSummary`, and related app-facing summaries expose string and nullable fields from validated CLI JSON. | Allowed app adapter boundary for I3. | Keep for now. A typed app DTO pass would need separate Flutter-side value models and UI coverage, and is not mechanical enough for this PR series. |
| Shell commands, argv fragments, terminal snippets, environment values, and diagnostic messages are primitive strings. | Allowed execution/diagnostic boundary. | Keep. Only branch-driving identities and constructor fronts with stable invariants are I3 conversion targets. |
| Custom lint invalid fixtures intentionally contain nullable, primitive, and part violations. | Allowed test fixture boundary. | Keep fixtures as diagnostics inputs. Update fixtures only when a new I3 lint rule is added in I3-P7. |

## Deferred Design Decisions

| Exposure | Reason deferred |
| --- | --- |
| App-side typed runner/runtime summary models. | The app consumes public CLI JSON and currently avoids fpdart/domain imports. A conversion would be an app model design gate, not a mechanical CLI/domain hardening step. |
| Unifying duplicated domain, platform, and I/O request-builder files. | I3-P2 and I3-P6 can remove primitive fronts inside the existing files, but selecting a single request-builder source of truth is architecture cleanup with broader blast radius. |
| Runtime-owner manifest schema redesign. | Runtime manifests are external/public inputs. I3 may type Konyak-owned domain state after parsing, but it must not rename or reinterpret manifest schema strings. |
| Broad nullable or primitive cleanup in Flutter widgets and framework callbacks. | These are Flutter framework boundaries and visible app workflow concerns. They require separate app architecture and test gates. |

## Next Gate Order

1. I3-P2 creates the runner-kind catalog first because later runtime platform
   typing needs the same stable runner-kind values.
2. I3-P3 converts runtime platform definition catalogs after runner kinds are
   centralized, paying attention to the current `const` catalog shape.
3. I3-P4 converts runtime model and source-manifest constructor fronts after
   platform definitions have typed ids, names, roles, and paths.
4. I3-P5 converts runtime install request wrapper fronts because they already
   delegate to typed runtime install operation models and can stay
   behavior-neutral.
5. I3-P6 converts macOS major-version capability plumbing after the request
   and runtime constructor fronts are typed.
6. I3-P7 adds governance and custom lint guardrails only for conversions
   completed by I3-P2 through I3-P6.
