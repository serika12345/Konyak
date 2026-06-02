part of '../../../konyak_cli.dart';

final class RuntimeComponentVersions {
  RuntimeComponentVersions(Map<String, String> versions)
    : _versions = versions
          .map(
            (componentId, version) => MapEntry(
              _requiredNonBlankDomainString(componentId, 'componentId'),
              _requiredNonBlankDomainString(version, 'version'),
            ),
          )
          .lock;

  const RuntimeComponentVersions.empty() : _versions = const IMapConst({});

  final IMap<String, String> _versions;

  bool get isEmpty => _versions.isEmpty;

  Map<String, String> toMap() => _versions.unlockView;

  RuntimeComponentVersions add(String componentId, String version) {
    return RuntimeComponentVersions(
      _versions
          .add(
            _requiredNonBlankDomainString(componentId, 'componentId'),
            _requiredNonBlankDomainString(version, 'version'),
          )
          .unlockView,
    );
  }

  String? operator [](String componentId) {
    return _versions[componentId];
  }

  @override
  bool operator ==(Object other) {
    return other is RuntimeComponentVersions && other._versions == _versions;
  }

  @override
  int get hashCode => _versions.hashCode;
}
