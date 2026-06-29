import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'bottle_runtime_settings_models.dart';

part 'bottle_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRecord with _$BottleRecord {
  const BottleRecord._();

  factory BottleRecord({
    required String id,
    required String name,
    required String path,
    required String windowsVersion,
    BottleRuntimeSettings? runtimeSettings,
    Iterable<PinnedProgramRecord> pinnedPrograms =
        const <PinnedProgramRecord>[],
  }) {
    return BottleRecord._validated(
      id: BottleId(id),
      name: BottleName(name),
      path: BottlePath(path),
      windowsVersion: WindowsVersion(windowsVersion),
      runtimeSettings: runtimeSettings ?? BottleRuntimeSettings(),
      pinnedPrograms: pinnedPrograms.toIList(),
    );
  }

  const factory BottleRecord._validated({
    required BottleId id,
    required BottleName name,
    required BottlePath path,
    required WindowsVersion windowsVersion,
    required BottleRuntimeSettings runtimeSettings,
    required IList<PinnedProgramRecord> pinnedPrograms,
  }) = _BottleRecord;

  BottleRecord withIdentity({
    required BottleId id,
    required BottleName name,
    required BottlePath path,
  }) {
    return BottleRecord._validated(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPath(BottlePath path) {
    return BottleRecord._validated(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withWindowsVersion(WindowsVersion windowsVersion) {
    return BottleRecord._validated(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withRuntimeSettings(BottleRuntimeSettings runtimeSettings) {
    return BottleRecord._validated(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms,
    );
  }

  BottleRecord withPinnedPrograms(
    Iterable<PinnedProgramRecord> pinnedPrograms,
  ) {
    return BottleRecord._validated(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: pinnedPrograms.toIList(),
    );
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PinnedProgramRecord with _$PinnedProgramRecord {
  const PinnedProgramRecord._();

  factory PinnedProgramRecord({
    required String name,
    required String path,
    bool removable = false,
    Option<String> iconPath = const Option.none(),
  }) {
    return PinnedProgramRecord._validated(
      name: ProgramName(name),
      path: ProgramPath(path),
      removable: removable,
      iconPath: iconPath.map(ProgramIconPath.new),
    );
  }

  const factory PinnedProgramRecord._validated({
    required ProgramName name,
    required ProgramPath path,
    required bool removable,
    required Option<ProgramIconPath> iconPath,
  }) = _PinnedProgramRecord;

  PinnedProgramRecord withName(ProgramName name) {
    return PinnedProgramRecord._validated(
      name: name,
      path: path,
      removable: removable,
      iconPath: iconPath,
    );
  }

  PinnedProgramRecord withIconPath(Option<ProgramIconPath> iconPath) {
    return PinnedProgramRecord._validated(
      name: name,
      path: path,
      removable: removable,
      iconPath: iconPath,
    );
  }
}
