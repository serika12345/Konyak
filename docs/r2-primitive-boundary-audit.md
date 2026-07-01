# R2 Primitive Boundary Audit

This audit is scoped to the runtime install planner/request path targeted by
R2-P1. Wider serialization and runtime execution primitives are recorded only
where they directly touch this path.

## Runtime Install Planner And Request Path

| Exposure | Category | R2-P1 action |
| --- | --- | --- |
| `RuntimeInstallRequestOperation.fullInstall`, `repair`, `componentInstall`, and `updateInstall` accept `Option<String>` install-source values and `Iterable<String>` component archive paths. | Semantic domain input that already has value objects. | Convert now to `Option<RuntimeArchivePath>`, `Option<RuntimeArchiveUrl>`, `Option<RuntimeArchiveChecksumValue>`, `Iterable<RuntimeArchivePath>`, `Option<RuntimeSourceManifestUrl>`, and `Option<RuntimeSourceManifestSignatureUrl>`. Keep raw CLI strings at platform request adapters. |
| `RuntimeInstallSource.fromOptions` accepts the same primitive install-source inputs. | Semantic domain helper input. | Convert with the request operation factories so the public runtime install source API is typed consistently. |
| `RuntimeWineInstallPlan.unsupported`, `incompleteWithoutSource`, `missingArchiveSource`, `RuntimePackageInstallResult.failed`, and source archive failure variants carry `String message`. | Diagnostic boundary primitive. | Accept for R2-P1. These strings are result copy surfaced to CLI/UI, not branch-driving domain identity. Revisit only if message codes, localization, or structured recovery becomes required. |
| `runtimeWineInstallPlan` accepts `unsupportedPlatformMessage`, `missingArchiveMessage`, and `incompleteRuntimeMessage`. | Diagnostic boundary primitive. | Accept for R2-P1 for the same reason as plan/result messages. |
| `RuntimeWineInstallPlan.downloadArchive.archiveFileName` and `runtimeWineInstallPlan.defaultArchiveFileName` are `String`. | Artifact filename primitive. | Defer. A `RuntimeArchiveFileName` value object is only worth adding if more filename behavior moves into domain planning. |
| `RuntimePackageInstallRequest.runtimeLabel` is `String` but validated as non-blank. | Presentation label primitive. | Accept for R2-P1. It is human-facing progress copy, not runtime identity. |
| `RuntimeInstallProgress.message` is `String`; `stage` is accepted as `String` and stored as `RuntimeInstallProgressStage`. | Progress presentation boundary. | Accept for R2-P1. Stage is already typed after construction; message remains presentation copy. |
| `runtimeStackSourceArchivePlan.tempDirectoryPath` is `String`. | Filesystem staging boundary primitive. | Defer to a runtime source archive planning gate if this API expands. It currently immediately produces typed `RuntimeArchivePath` values and is outside the R2-P1 request API conversion. |
| `RuntimeDefinition`, `RuntimeRecord`, `RuntimeStack`, `RuntimeStackBackend`, `RuntimeStackComponent`, `RuntimeSourceManifest`, and `RuntimeSourceComponent` constructors accept raw strings and validate into typed internal state. | External data construction boundary. | Defer to R2-P2 serialization boundary work. These factories are compatibility-friendly entry points for decoded metadata and already store typed state internally. |
| `RuntimeSourceManifest.componentById(String id)` accepts a raw component id. | Domain query primitive. | Defer to a later R2-S2 conversion candidate. Converting it is small but unrelated to the install request source input path selected for R2-P1. |

## First Conversion

R2-P1 converts the runtime install request/source option APIs because the
invariants already exist as value objects and the raw strings cross a
domain-facing planner/request boundary. The macOS and Linux platform request
objects remain the raw CLI adapter boundary and convert strings before creating
domain request operations.
