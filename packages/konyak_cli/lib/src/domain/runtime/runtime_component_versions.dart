import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';

/// Intentionally hand-written instead of Freezed: generated fields would expose
/// the internal immutable map used to preserve validated component versions.
final class RuntimeComponentVersions {
  RuntimeComponentVersions(Map<String, String> versions)
    : _versions = versions
          .map(
            (componentId, version) => MapEntry(
              RuntimeComponentId(componentId),
              RuntimeVersion(version),
            ),
          )
          .lock;

  const RuntimeComponentVersions.empty() : _versions = const IMapConst({});

  final IMap<RuntimeComponentId, RuntimeVersion> _versions;

  bool get isEmpty => _versions.isEmpty;

  Map<String, String> toMap() {
    return _versions.map((componentId, version) {
      return MapEntry(componentId.value, version.value);
    }).unlockView;
  }

  RuntimeComponentVersions add(
    RuntimeComponentId componentId,
    RuntimeVersion version,
  ) {
    return RuntimeComponentVersions._withVersions(
      _versions.add(componentId, version),
    );
  }

  Option<RuntimeVersion> operator [](RuntimeComponentId componentId) {
    if (!_versions.containsKey(componentId)) {
      return const Option.none();
    }

    return Option.of(_versions[componentId] as RuntimeVersion);
  }

  RuntimeComponentVersions._withVersions(this._versions);

  @override
  bool operator ==(Object other) {
    return other is RuntimeComponentVersions && other._versions == _versions;
  }

  @override
  int get hashCode => _versions.hashCode;
}
