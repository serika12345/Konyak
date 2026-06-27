part of '../../../konyak_cli.dart';

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

  RuntimeComponentVersions add(String componentId, String version) {
    return RuntimeComponentVersions._withVersions(
      _versions.add(RuntimeComponentId(componentId), RuntimeVersion(version)),
    );
  }

  String? operator [](String componentId) {
    return _versions[RuntimeComponentId(componentId)]?.value;
  }

  RuntimeComponentVersions._withVersions(this._versions);

  @override
  bool operator ==(Object other) {
    return other is RuntimeComponentVersions && other._versions == _versions;
  }

  @override
  int get hashCode => _versions.hashCode;
}
