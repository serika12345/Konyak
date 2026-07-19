# Compatibility profile versioning

Profile manifests contain two independent version concepts.

## `schemaVersion`

`schemaVersion` identifies the complete JSON document contract understood by a
Konyak release. Version 1 requires the canonical `$schema` URI declared in the
[runtime schema](https://raw.githubusercontent.com/serika12345/Konyak/main/packages/konyak_cli/profiles/profile.schema.json).
The versioned human reference is [schema-v1.md](schema-v1.md).

The following changes may update the version 1 documentation without changing
`schemaVersion`:

- descriptions, examples, links, or other validation-neutral annotations;
- clarification of already enforced JSON Schema or Dart domain behavior;
- generator and presentation changes that leave accepted manifests unchanged.

A new `schemaVersion` is required when the supported manifest language changes,
including a new optional field or action. Version 1 objects reject unknown
fields, so even an apparently optional capability would be rejected by older
Konyak releases. A new version therefore needs an explicit runtime decoder,
schema, generated reference, migration/compatibility decision, and tests before
profiles may use it.

If an unsafe manifest must be rejected as a security correction, Konyak may
tighten current validation before a new format is available. Such a correction
must be called out in release notes and covered by a regression test; it is not
treated as a routine documentation-only change.

## `profileVersion`

`profileVersion` is the revision of one profile's content. It does not grant
access to new schema capabilities. Increase it when resource digests, install
actions, compatibility rules, paths, or other behavior for that profile changes.

The root profile and nested `compatibilityProfile` have separate revision
fields because install behavior and launch compatibility rules are distinct
records. Authors should normally keep them aligned unless those records are
versioned independently for a documented reason.

## Source-of-truth policy

The runtime JSON Schema and Dart domain constructors are the executable
contract. The generated field reference is committed for review and checked in
CI; contributors edit the schema annotations and regenerate the reference
instead of editing `schema-v1.md` directly:

```sh
nix develop -c zsh -lc 'just generate-profile-schema-docs'
nix develop -c zsh -lc 'just verify-profile-schema-docs'
```

The authored guides explain workflows and compatibility policy, while stable
semantic rule IDs link non-Schema domain checks to behavioral tests. This keeps
documentation drift detectable without pretending that JSON Schema alone
defines all runtime behavior.
