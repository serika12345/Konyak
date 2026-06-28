import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'bottle_runtime_settings_models.dart';

class BottleRecord {
  BottleRecord({
    required String id,
    required String name,
    required String path,
    required String windowsVersion,
    BottleRuntimeSettings? runtimeSettings,
    Iterable<PinnedProgramRecord> pinnedPrograms =
        const <PinnedProgramRecord>[],
  }) : id = BottleId(id),
       name = BottleName(name),
       path = BottlePath(path),
       windowsVersion = WindowsVersion(windowsVersion),
       runtimeSettings = runtimeSettings ?? BottleRuntimeSettings(),
       pinnedPrograms = pinnedPrograms.toIList();

  final BottleId id;
  final BottleName name;
  final BottlePath path;
  final WindowsVersion windowsVersion;
  final BottleRuntimeSettings runtimeSettings;
  final IList<PinnedProgramRecord> pinnedPrograms;

  BottleRecord withIdentity({
    required String id,
    required String name,
    required String path,
  }) {
    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion.value,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPath(String path) {
    return BottleRecord(
      id: id.value,
      name: name.value,
      path: path,
      windowsVersion: windowsVersion.value,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withWindowsVersion(String windowsVersion) {
    return BottleRecord(
      id: id.value,
      name: name.value,
      path: path.value,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withRuntimeSettings(BottleRuntimeSettings runtimeSettings) {
    return BottleRecord(
      id: id.value,
      name: name.value,
      path: path.value,
      windowsVersion: windowsVersion.value,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPinnedPrograms(
    Iterable<PinnedProgramRecord> pinnedPrograms,
  ) {
    return BottleRecord(
      id: id.value,
      name: name.value,
      path: path.value,
      windowsVersion: windowsVersion.value,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id.value,
      'name': name.value,
      'path': path.value,
      'windowsVersion': windowsVersion.value,
      if (runtimeSettings != BottleRuntimeSettings())
        'runtimeSettings': runtimeSettings.toJson(),
      if (pinnedPrograms.isNotEmpty)
        'pinnedPrograms': pinnedPrograms
            .map((program) => program.toJson())
            .toList(),
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
        other.pinnedPrograms == pinnedPrograms;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      path,
      windowsVersion,
      runtimeSettings,
      pinnedPrograms,
    );
  }
}

class PinnedProgramRecord {
  PinnedProgramRecord({
    required String name,
    required String path,
    this.removable = false,
    Option<String> iconPath = const Option.none(),
  }) : name = ProgramName(name),
       path = ProgramPath(path),
       iconPath = iconPath.map(ProgramIconPath.new);

  final ProgramName name;
  final ProgramPath path;
  final bool removable;
  final Option<ProgramIconPath> iconPath;

  PinnedProgramRecord withName(String name) {
    return PinnedProgramRecord(
      name: name,
      path: path.value,
      removable: removable,
      iconPath: iconPath.map((value) => value.value),
    );
  }

  PinnedProgramRecord withIconPath(Option<String> iconPath) {
    return PinnedProgramRecord(
      name: name.value,
      path: path.value,
      removable: removable,
      iconPath: iconPath,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name.value,
      'path': path.value,
      'removable': removable,
      ...iconPath.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'iconPath': value.value},
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
