# R2 Serialization Boundary Audit

This audit is scoped to R2-P2. The goal is to keep model objects focused on
state and behavior while CLI modules own the JSON shape consumed by Flutter,
tests, and persisted command contracts.

## Current Projection Inventory

| Projection | Current owner | R2-P2 action |
| --- | --- | --- |
| `MacosSetupStatus.toJson`, `RosettaSetupStatus.toJson`, and `RuntimeSetupStatus.toJson` | macOS platform setup model objects | Convert now to CLI serialization helpers. This is stable `check-macos-setup --json` output and has direct CLI contract coverage. |
| `GptkWineInstallRecord.toJson` | GPTK runtime I/O model object | Convert now to CLI serialization helpers. This is stable `install-gptk-wine --json` output and is adjacent to the same runtime command handler. |
| CLI runtime records, update records, validation results, graphics hints, program catalogs, and bottle records | CLI serializer modules such as `cli_runtime_record_json.dart`, `cli_update_json.dart`, and `cli_runtime_validation_json.dart` | Already at the CLI boundary. No R2-P2 movement needed. |
| Domain model files under `packages/konyak_cli/lib/src/domain` | Domain layer | No `toJson` projections remain in source or generated domain files at the start of R2-P2. Continue to enforce this through review and future governance work. |

## Deferred Work

- R2-S4 remains open for any future JSON projection discovered in domain models.
- R2-S5 remains open for removing hand-written `part` usage from CLI contract
  tests; it is unrelated to the model-to-CLI serializer move in this gate.
