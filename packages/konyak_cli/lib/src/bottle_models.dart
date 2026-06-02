part of '../konyak_cli.dart';

class BottleRecord {
  BottleRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.windowsVersion,
    this.runtimeSettings = const BottleRuntimeSettings(),
    List<PinnedProgramRecord> pinnedPrograms = const <PinnedProgramRecord>[],
  }) : pinnedPrograms = List.unmodifiable(pinnedPrograms);

  final String id;
  final String name;
  final String path;
  final String windowsVersion;
  final BottleRuntimeSettings runtimeSettings;
  final List<PinnedProgramRecord> pinnedPrograms;

  BottleRecord copyWith({
    String? id,
    String? name,
    String? path,
    String? windowsVersion,
    BottleRuntimeSettings? runtimeSettings,
    List<PinnedProgramRecord>? pinnedPrograms,
  }) {
    return BottleRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      windowsVersion: windowsVersion ?? this.windowsVersion,
      runtimeSettings: runtimeSettings ?? this.runtimeSettings,
      pinnedPrograms: pinnedPrograms ?? this.pinnedPrograms,
    );
  }

  static BottleRecord? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final Object? id = value['id'];
    final Object? name = value['name'];
    final Object? path = value['path'];
    final Object? windowsVersion = value['windowsVersion'];

    if (id is! String ||
        name is! String ||
        path is! String ||
        windowsVersion is! String) {
      return null;
    }

    final runtimeSettings = BottleRuntimeSettings.fromJson(
      value['runtimeSettings'],
    );
    if (runtimeSettings == null) {
      return null;
    }

    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: _parsePinnedPrograms(value['pinnedPrograms']),
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
  const PinnedProgramRecord({
    required this.name,
    required this.path,
    this.removable = false,
    this.iconPath,
  });

  final String name;
  final String path;
  final bool removable;
  final String? iconPath;

  PinnedProgramRecord copyWith({
    String? name,
    String? path,
    bool? removable,
    String? iconPath,
  }) {
    return PinnedProgramRecord(
      name: name ?? this.name,
      path: path ?? this.path,
      removable: removable ?? this.removable,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'path': path,
      'removable': removable,
      if (iconPath != null) 'iconPath': iconPath,
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
