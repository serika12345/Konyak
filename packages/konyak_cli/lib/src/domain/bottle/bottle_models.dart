import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../program/program_profile_models.dart';
import '../shared/domain_value_objects.dart';
import 'bottle_runtime_settings_models.dart';

part 'bottle_models.freezed.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class BottleRecord with _$BottleRecord {
  const BottleRecord._();

  factory BottleRecord({
    required String id,
    required String name,
    required String path,
    required String windowsVersion,
    Option<BottleRuntimeSettings> runtimeSettings = const Option.none(),
    Iterable<PinnedProgramRecord> pinnedPrograms =
        const <PinnedProgramRecord>[],
    Iterable<ProgramProfileRecord> programProfiles =
        const <ProgramProfileRecord>[],
  }) {
    return BottleRecord._validated(
      id: BottleId(id),
      name: BottleName(name),
      path: BottlePath(path),
      windowsVersion: WindowsVersion(windowsVersion),
      runtimeSettings: runtimeSettings.match(
        BottleRuntimeSettings.new,
        (settings) => settings,
      ),
      pinnedPrograms: pinnedPrograms.toIList(),
      programProfiles: programProfiles.toIList(),
    );
  }

  const factory BottleRecord._validated({
    required BottleId id,
    required BottleName name,
    required BottlePath path,
    required WindowsVersion windowsVersion,
    required BottleRuntimeSettings runtimeSettings,
    required IList<PinnedProgramRecord> pinnedPrograms,
    required IList<ProgramProfileRecord> programProfiles,
  }) = _BottleRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
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
}
