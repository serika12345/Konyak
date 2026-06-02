part of '../konyak_cli.dart';

class BottleRecord {
  BottleRecord({
    required String id,
    required String name,
    required String path,
    required String windowsVersion,
    this.runtimeSettings = const BottleRuntimeSettings(),
    List<PinnedProgramRecord> pinnedPrograms = const <PinnedProgramRecord>[],
  }) : id = _requiredNonBlankDomainString(id, 'id'),
       name = _requiredNonBlankDomainString(name, 'name'),
       path = _requiredNonBlankDomainString(path, 'path'),
       windowsVersion = _requiredNonBlankDomainString(
         windowsVersion,
         'windowsVersion',
       ),
       pinnedPrograms = List.unmodifiable(pinnedPrograms);

  final String id;
  final String name;
  final String path;
  final String windowsVersion;
  final BottleRuntimeSettings runtimeSettings;
  final List<PinnedProgramRecord> pinnedPrograms;

  BottleRecord withIdentity({
    required String id,
    required String name,
    required String path,
  }) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPath(String path) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withWindowsVersion(String windowsVersion) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withRuntimeSettings(BottleRuntimeSettings runtimeSettings) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPinnedPrograms(List<PinnedProgramRecord> pinnedPrograms) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'path': path,
      'windowsVersion': windowsVersion,
      if (runtimeSettings != const BottleRuntimeSettings())
        'runtimeSettings': runtimeSettings.toJson(),
      if (pinnedPrograms.isNotEmpty)
        'pinnedPrograms': pinnedPrograms
            .map((program) => program.toJson())
            .toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is BottleRecord &&
        other.id == id &&
        other.name == name &&
        other.path == path &&
        other.windowsVersion == windowsVersion &&
        other.runtimeSettings == runtimeSettings &&
        _listEquals(other.pinnedPrograms, pinnedPrograms);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      path,
      windowsVersion,
      runtimeSettings,
      Object.hashAll(pinnedPrograms),
    );
  }
}

class PinnedProgramRecord {
  PinnedProgramRecord({
    required String name,
    required String path,
    this.removable = false,
    Option<String> iconPath = const Option.none(),
  }) : name = _requiredNonBlankDomainString(name, 'name'),
       path = _requiredNonBlankDomainString(path, 'path'),
       iconPath = iconPath.map(
         (value) => _requiredNonBlankDomainString(value, 'iconPath'),
       );

  final String name;
  final String path;
  final bool removable;
  final Option<String> iconPath;

  PinnedProgramRecord withName(String name) {
    return PinnedProgramRecord(
      name: name,
      path: path,
      removable: removable,
      iconPath: iconPath,
    );
  }

  PinnedProgramRecord withIconPath(Option<String> iconPath) {
    return PinnedProgramRecord(
      name: name,
      path: path,
      removable: removable,
      iconPath: iconPath,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'path': path,
      'removable': removable,
      ...iconPath.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'iconPath': value},
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedProgramRecord &&
        other.name == name &&
        other.path == path &&
        other.removable == removable &&
        other.iconPath == iconPath;
  }

  @override
  int get hashCode => Object.hash(name, path, removable, iconPath);
}

String _requiredNonBlankDomainString(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return value;
}
