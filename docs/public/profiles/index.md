# Author a compatibility profile

A Konyak compatibility profile describes how to install one Windows program
and which bounded compatibility rules Konyak applies to it. The manifest is
declarative JSON: every accepted action is part of Konyak's reviewed schema and
runtime implementation.

The current contract is schema version 1. Use these documents together:

- [Schema v1 field reference](schema-v1.md) lists every field and constraint.
- [Validation layers](validation.md) explains checks that JSON Schema alone
  cannot express.
- [Versioning policy](versioning.md) distinguishes schema revisions from
  profile revisions.

## Start from a canonical manifest

The bundled [Steam manifest](https://github.com/serika12345/Konyak/blob/main/packages/konyak_cli/profiles/steam.json)
is the canonical complete example. Copy it to a working directory outside
`packages/konyak_cli/profiles`; that directory is reserved for profiles shipped
with Konyak, not community examples or user-owned manifests.

For a new profile:

1. Keep `$schema` and `schemaVersion` unchanged.
2. Choose a stable lowercase `id`, and normally use the same identity for
   `compatibilityProfile.id`.
3. Set `profileVersion` values to the revision you are publishing. Increase
   them when the profile's behavior or resources change.
4. Declare only the host platforms on which the profile's behavior has been
   verified. In schema version 1, `childProcessRules` and
   `installerCompletion` are effective on macOS only.
5. Use HTTPS resources with reviewed filenames and exact SHA-256 digests.
   Prefer immutable, versioned URLs. Konyak verifies the downloaded bytes; it
   does not trust the filename or URL alone.
6. Add only the pre-install actions represented by the schema. Profiles cannot
   contain arbitrary scripts or commands.

## Validate before importing

Run the same CLI/domain validation used by the application:

```sh
nix develop -c zsh -lc \
  'cd packages/konyak_cli && dart run bin/konyak.dart \
  validate-install-profile --from /absolute/path/to/profile.json --json'
```

A valid manifest exits with code 0 and returns an
`installProfileMutation.operation` value of `validate`. An invalid manifest
exits with code 65 and returns structured `validationErrors` containing an
instance `path` and `message`. Validation does not write to the user profile
library.

After validation, import through Konyak's Profile Manager or the public CLI
contract:

```sh
nix develop -c zsh -lc \
  'cd packages/konyak_cli && dart run bin/konyak.dart \
  import-install-profile --from /absolute/path/to/profile.json --json'
```

Import canonicalizes the accepted JSON and stores it as `<id>.json` in
Konyak's platform data directory. A user profile cannot replace a bundled
profile or a different user profile with the same ID.

## Review checklist

- Validation succeeds through `validate-install-profile --json`.
- The profile ID, program path, Windows version, and declared platforms match
  the intended program.
- Every downloaded resource uses HTTPS and its digest was calculated from the
  intended upstream artifact.
- Pre-install actions are minimal and architecture/destination pairs are
  correct.
- macOS-only behavior is not presented as Linux support.
- Resource licensing and redistribution terms are understood before proposing
  a profile for bundling.
