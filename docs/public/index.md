# Konyak documentation

Konyak manages Wine and Proton bottles through a Flutter application backed by
a versioned Dart CLI contract.

## Compatibility profiles

- [Author a compatibility profile](profiles/index.md)
- [Understand validation and error layers](profiles/validation.md)
- [Understand profile schema versioning](profiles/versioning.md)
- [Browse the generated schema v1 reference](profiles/schema-v1.md)
- [Download the raw schema v1 mirror][raw-schema]

Compatibility profiles are declarative data. They cannot run arbitrary shell
commands or embed platform scripts.

[raw-schema]: https://serika12345.github.io/Konyak/schemas/profile-v1.schema.json
