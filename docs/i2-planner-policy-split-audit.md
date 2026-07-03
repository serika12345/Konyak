# I2 Planner Policy Split Audit

This audit records the remaining `ProgramRunPlanner` policy split candidates
after I2-P5. It is behavior-neutral: it does not change public CLI JSON, argv,
exit codes, app behavior, runtime behavior, or Wine execution paths.

## Inventory Basis

- `ProgramRunPlanner` now receives typed inputs for program paths, bottle
  commands, winetricks verbs, Wine process ids, Windows versions, and runtime
  settings.
- I2-P5 moved bottle-command selection to `SupportedBottleCommand` plus
  `BottleCommandPlanKind`, so the planner no longer chooses command behavior by
  comparing raw command strings.
- Remaining planner policy is concentrated in host-platform dispatch,
  macOS-version propagation, registry macOS-driver inclusion, and
  graphics-backend suggestion policy.

## Planner Host Dispatch

| Exposure | Category | I2 action |
| --- | --- | --- |
| `ProgramRunPlanner.plan`, `planBottleCommand`, prefix bootstrap, Wine process, winetricks, and registry methods switch on `KonyakHostPlatform` to choose Linux or macOS request builders. | Deferred design decision. The switches are visible, but each branch delegates to already split request-builder functions with typed arguments. Splitting now would mostly move switch expressions without reducing behavior coupling. | Keep for now. Reassess only when an implementation gate can remove duplicated host dispatch across multiple methods or when a third platform appears. |
| The planner stores `HostEnvironment` and passes it through request builders. | Allowed orchestration state. The planner remains the boundary that supplies host environment to request construction without performing I/O. | Keep. Do not introduce environment service abstractions unless request construction starts doing I/O. |
| `macosMajorVersion` is carried as `Option<int>` through macOS request builders and terminal helpers. | Candidate, but not first. It is a macOS capability input, but current use is limited to D3DMetal DLSS/MetalFX environment selection and terminal setup. | Defer until a macOS capability model has at least one more consumer or the D3DMetal environment policy is split. |

## Runner Kind Policy

| Exposure | Category | I2 action |
| --- | --- | --- |
| Linux and macOS request builders construct `RunnerKind` from string literals such as `wine`, `macosWine`, `winedbg`, and `macosWinedbg`. | Deferred design decision. `RunnerKind` is already a value object, and the string values are stable CLI/result contract data. | Do not type as an enum in I2. A stricter runner-kind model would be a public contract audit because tests and CLI JSON assert these values. |
| Request-builder files duplicate runner-kind naming across normal Wine, registry, wineboot, wineserver, winedbg, terminal, and winetricks requests. | Candidate only if paired with request family extraction. The duplication is explicit and easy to audit; extracting constants alone would preserve implementation detail as governance. | Defer. Only convert with a behavior-focused request family gate. |

## Registry Policy

| Exposure | Category | I2 action |
| --- | --- | --- |
| `ProgramRunPlanner.planRuntimeSettingsRegistryUpdates` and `planBottleSettingsRegistryQueries` pass `includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos` into registry plan helpers. | Candidate for next implementation gate. This is stable platform policy, not JSON or runtime execution. `includeMacDriverSettings` decides whether macOS Wine Mac Driver registry values participate in runtime settings sync and query. | Add a focused gate that replaces the raw boolean with an explicit registry planning policy while keeping generated registry updates, queries, argv, and CLI behavior identical. |
| `runtimeSettingsRegistryUpdates` applies high-resolution DPI adjustment only when Mac Driver settings are included. | Candidate under the same gate. This behavior belongs with registry planning policy, and tests already cover runtime settings registry effects. | Include in the registry policy gate with focused macOS/Linux tests. |
| `windowsVersionRegistryUpdates` has no platform policy. | Already stable. | Keep unchanged. |

## Graphics Backend Policy

| Exposure | Category | I2 action |
| --- | --- | --- |
| `programGraphicsBackendHintsFromSignals` maps detected Direct3D signals to platform-specific suggestions. | Deferred design decision. The policy is already outside `ProgramRunPlanner` and has focused CLI contract tests for macOS and Linux. | Do not split in I2-P7. Revisit only if suggestions need user-configurable strategy, confidence tuning, or shared runtime capability data. |
| macOS request builders choose D3DMetal, DXMT, or DXVK environment paths from `BottleRuntimeSettings`. Linux request builders choose DXVK and vkd3d-proton DLL paths and overrides. | Deferred runtime request policy. This is tightly coupled to runtime layout and existing CLI runtime/process tests. | Do not move during planner cleanup. Any change here needs a runtime request-builder gate with CLI contract coverage. |

## Platform Request Builder Duplication

| Exposure | Category | I2 action |
| --- | --- | --- |
| Domain request builders under `packages/konyak_cli/lib/src/domain/program` and platform request builders under `packages/konyak_cli/lib/src/platform` contain similar macOS/Linux request construction code. | Deferred architecture cleanup. The platform files are still referenced by I/O/runtime validation paths, while `ProgramRunPlanner` uses the domain request-builder exports. | Do not merge in I2-P7. A later gate should first decide which request-builder path is the source of truth and preserve public execution path tests. |

## Next Gate Decision

The next safe implementation gate is registry planner platform policy:

1. It is smaller than host request-family extraction.
2. It removes the remaining raw platform boolean from planner-to-registry
   calls.
3. It has observable behavior that can be tested without runtime execution:
   macOS includes Mac Driver registry values, Linux excludes them, and argv
   remains unchanged.
4. It does not require public CLI JSON, argv, exit-code, app, runtime, or Wine
   behavior changes.

Host request-family extraction, runner-kind typing, graphics-backend policy
splitting, and platform request-builder unification are explicitly deferred
until a later gate identifies a boundary that reduces responsibility instead of
only moving conditionals.
