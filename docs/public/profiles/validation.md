# Compatibility profile validation

Konyak validates external profile data before it becomes application state.
Passing a generic JSON Schema validator is necessary, but it is not the whole
acceptance contract.

## Validation layers

### 1. Input envelope

The manifest must exist, be no larger than 1 MiB (1,048,576 bytes), contain
valid UTF-8, and decode as JSON. Malformed JSON, invalid UTF-8, and oversized
files are rejected without changing the profile catalog.

### 2. JSON Schema

The runtime [JSON Schema](https://raw.githubusercontent.com/serika12345/Konyak/main/packages/konyak_cli/profiles/profile.schema.json)
checks the document shape, required fields, closed objects, discriminated
pre-install actions, patterns, enum values, array bounds, and the macOS-only
`installerCompletion` condition. The generated [schema v1 reference](schema-v1.md)
is derived deterministically from that source.

### 3. Dart semantic validation

Validated JSON is decoded into immutable domain values. The following stable
rule IDs cover constraints that schema version 1 does not express completely:

| Rule ID | Requirement |
| --- | --- |
| `pre-install-actions.unique-winetricks-verbs` | A winetricks verb occurs at most once. |
| `pre-install-actions.unique-native-dll-targets` | A destination and case-insensitive target DLL basename occur at most once. |
| `child-process-rules.non-blank-executable-suffix` | A printable suffix must contain a non-whitespace character. |
| `child-process-rules.total-argument-limit` | All child-process rules contain at most 64 appended arguments in total. |
| `child-process-rules.serialized-length-limit` | The serialized rule set is at most 65,535 UTF-16 code units. |

These IDs are stored as schema annotations so the generated reference and the
behavioral tests cannot silently drift apart.

### 4. Profile library lifecycle

Validation is read-only. Import and later mutations add storage rules:

- accepted input is re-encoded as canonical JSON before it is written;
- a bundled profile ID is read-only and cannot be shadowed, updated, or
  deleted;
- importing different content over an existing user ID is a conflict;
- update and delete require the SHA-256 digest observed when the profile was
  inspected, preventing a stale editor from overwriting a concurrent change;
- a user profile filename must be `<id>.json` when the catalog is loaded.

## CLI result contract

Use `validate-install-profile --from <path> --json` for a non-mutating check.
All machine-readable results include the CLI contract version. On validation
failure, inspect `error.code` and `error.validationErrors`; do not parse human
diagnostics.

Profile library exit codes are stable command behavior:

| Exit code | Meaning |
| --- | --- |
| `0` | Operation succeeded. |
| `65` | The manifest is invalid. |
| `66` | The requested profile does not exist. |
| `73` | An ID conflict occurred or the inspected profile was modified. |
| `74` | Reading or writing profile data failed. |
| `77` | The requested mutation targets a bundled read-only profile. |

An invalid edit must remain in the editor with Save disabled. An invalid import
must leave the visible catalog unchanged. These UI behaviors follow from the
same validation result instead of maintaining a separate Flutter validator.
