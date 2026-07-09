import 'dart:collection';

import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_value_objects.freezed.dart';

sealed class DomainValueObject<T extends Object> {
  const DomainValueObject();

  T get value;
}

sealed class StringDomainValueObject implements DomainValueObject<String> {
  const StringDomainValueObject();
}

sealed class IntDomainValueObject implements DomainValueObject<int> {
  const IntDomainValueObject();
}

sealed class DoubleDomainValueObject implements DomainValueObject<double> {
  const DoubleDomainValueObject();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppId with _$AppId implements StringDomainValueObject {
  const AppId._();

  factory AppId(String value) =>
      AppId._validated(_requiredValueObjectString(value, 'appId'));

  const factory AppId._validated(String value) = _AppId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleId with _$BottleId implements StringDomainValueObject {
  const BottleId._();

  factory BottleId(String value) =>
      BottleId._validated(_requiredValueObjectString(value, 'bottleId'));

  const factory BottleId._validated(String value) = _BottleId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleName with _$BottleName implements StringDomainValueObject {
  const BottleName._();

  factory BottleName(String value) =>
      BottleName._validated(_requiredValueObjectString(value, 'bottleName'));

  const factory BottleName._validated(String value) = _BottleName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottlePath with _$BottlePath implements StringDomainValueObject {
  const BottlePath._();

  factory BottlePath(String value) =>
      BottlePath._validated(_requiredValueObjectString(value, 'bottlePath'));

  const factory BottlePath._validated(String value) = _BottlePath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchivePath
    with _$BottleArchivePath
    implements StringDomainValueObject {
  const BottleArchivePath._();

  factory BottleArchivePath(String value) => BottleArchivePath._validated(
    _requiredValueObjectString(value, 'bottleArchivePath'),
  );

  const factory BottleArchivePath._validated(String value) = _BottleArchivePath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WindowsVersion
    with _$WindowsVersion
    implements StringDomainValueObject {
  const WindowsVersion._();

  factory WindowsVersion(String value) => WindowsVersion._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'windowsVersion',
      allowedValues: allowedValues,
    ),
  );

  const factory WindowsVersion._validated(String value) = _WindowsVersion;

  static const allowedValues = <String>{
    'winxp64',
    'win7',
    'win8',
    'win81',
    'win10',
    'win11',
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class EnhancedSyncMode
    with _$EnhancedSyncMode
    implements StringDomainValueObject {
  const EnhancedSyncMode._();

  factory EnhancedSyncMode(String value) => EnhancedSyncMode._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'enhancedSync',
      allowedValues: allowedValues,
    ),
  );

  const factory EnhancedSyncMode._validated(String value) = _EnhancedSyncMode;

  static const none = EnhancedSyncMode._validated('none');
  static const esync = EnhancedSyncMode._validated('esync');
  static const msync = EnhancedSyncMode._validated('msync');
  static const allowedValues = <String>{'none', 'esync', 'msync'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class DxvkHudMode
    with _$DxvkHudMode
    implements StringDomainValueObject {
  const DxvkHudMode._();

  factory DxvkHudMode(String value) => DxvkHudMode._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'dxvkHud',
      allowedValues: allowedValues,
    ),
  );

  const factory DxvkHudMode._validated(String value) = _DxvkHudMode;

  static const full = DxvkHudMode._validated('full');
  static const partial = DxvkHudMode._validated('partial');
  static const fps = DxvkHudMode._validated('fps');
  static const off = DxvkHudMode._validated('off');
  static const allowedValues = <String>{'full', 'partial', 'fps', 'off'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WindowsBuildVersion
    with _$WindowsBuildVersion
    implements IntDomainValueObject {
  const WindowsBuildVersion._();

  factory WindowsBuildVersion(int value) => WindowsBuildVersion._validated(
    _requiredBoundedValueObjectInt(
      value: value,
      fieldName: 'buildVersion',
      minimum: 0,
      maximum: 999999,
    ),
  );

  const factory WindowsBuildVersion._validated(int value) =
      _WindowsBuildVersion;

  static const none = WindowsBuildVersion._validated(0);
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WindowsDpiScaling
    with _$WindowsDpiScaling
    implements IntDomainValueObject {
  const WindowsDpiScaling._();

  factory WindowsDpiScaling(int value) => WindowsDpiScaling._validated(
    _requiredBoundedValueObjectInt(
      value: value,
      fieldName: 'dpiScaling',
      minimum: 96,
      maximum: 480,
      step: Option.of(24),
    ),
  );

  const factory WindowsDpiScaling._validated(int value) = _WindowsDpiScaling;

  static const standard = WindowsDpiScaling._validated(96);
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class MacosMajorVersion
    with _$MacosMajorVersion
    implements IntDomainValueObject {
  const MacosMajorVersion._();

  factory MacosMajorVersion(int value) => MacosMajorVersion._validated(
    _requiredBoundedValueObjectInt(
      value: value,
      fieldName: 'macosMajorVersion',
      minimum: 1,
      maximum: 999,
    ),
  );

  const factory MacosMajorVersion._validated(int value) = _MacosMajorVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSettingsControlKey
    with _$RuntimeSettingsControlKey
    implements StringDomainValueObject {
  const RuntimeSettingsControlKey._();

  factory RuntimeSettingsControlKey(String value) =>
      RuntimeSettingsControlKey._validated(
        _requiredAllowedValueObjectString(
          value: value,
          fieldName: 'runtimeSettingsControlKey',
          allowedValues: allowedValues,
        ),
      );

  const factory RuntimeSettingsControlKey._validated(String value) =
      _RuntimeSettingsControlKey;

  static const allowedValues = <String>{
    'retinaMode',
    'buildVersion',
    'enhancedSync',
    'dpiScaling',
    'avxEnabled',
    'graphicsBackend',
    'dxvkAsync',
    'dxvkHud',
    'vkd3dProton',
    'metalHud',
    'metalTrace',
    'dlssMetalFx',
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramId with _$ProgramId implements StringDomainValueObject {
  const ProgramId._();

  factory ProgramId(String value) =>
      ProgramId._validated(_requiredValueObjectString(value, 'programId'));

  const factory ProgramId._validated(String value) = _ProgramId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileId with _$ProfileId implements StringDomainValueObject {
  const ProfileId._();

  factory ProfileId(String value) => ProfileId._validated(
    _requiredIdentifierValueObjectString(value, 'profileId'),
  );

  const factory ProfileId._validated(String value) = _ProfileId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileName
    with _$ProfileName
    implements StringDomainValueObject {
  const ProfileName._();

  factory ProfileName(String value) =>
      ProfileName._validated(_requiredValueObjectString(value, 'profileName'));

  const factory ProfileName._validated(String value) = _ProfileName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileSummary
    with _$ProfileSummary
    implements StringDomainValueObject {
  const ProfileSummary._();

  factory ProfileSummary(String value) => ProfileSummary._validated(
    _requiredValueObjectString(value, 'profileSummary'),
  );

  const factory ProfileSummary._validated(String value) = _ProfileSummary;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileVersion
    with _$ProfileVersion
    implements IntDomainValueObject {
  const ProfileVersion._();

  factory ProfileVersion(int value) => ProfileVersion._validated(
    _requiredBoundedValueObjectInt(
      value: value,
      fieldName: 'profileVersion',
      minimum: 1,
      maximum: 999999,
    ),
  );

  const factory ProfileVersion._validated(int value) = _ProfileVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramName
    with _$ProgramName
    implements StringDomainValueObject {
  const ProgramName._();

  factory ProgramName(String value) =>
      ProgramName._validated(_requiredValueObjectString(value, 'programName'));

  const factory ProgramName._validated(String value) = _ProgramName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramPath
    with _$ProgramPath
    implements StringDomainValueObject {
  const ProgramPath._();

  factory ProgramPath(String value) =>
      ProgramPath._validated(_requiredValueObjectString(value, 'programPath'));

  const factory ProgramPath._validated(String value) = _ProgramPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramIconPath
    with _$ProgramIconPath
    implements StringDomainValueObject {
  const ProgramIconPath._();

  factory ProgramIconPath(String value) => ProgramIconPath._validated(
    _requiredValueObjectString(value, 'programIconPath'),
  );

  const factory ProgramIconPath._validated(String value) = _ProgramIconPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramExecutable
    with _$ProgramExecutable
    implements StringDomainValueObject {
  const ProgramExecutable._();

  factory ProgramExecutable(String value) => ProgramExecutable._validated(
    _requiredValueObjectString(value, 'programExecutable'),
  );

  const factory ProgramExecutable._validated(String value) = _ProgramExecutable;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramWorkingDirectoryPath
    with _$ProgramWorkingDirectoryPath
    implements StringDomainValueObject {
  const ProgramWorkingDirectoryPath._();

  factory ProgramWorkingDirectoryPath(String value) =>
      ProgramWorkingDirectoryPath._validated(
        _requiredValueObjectString(value, 'programWorkingDirectory'),
      );

  const factory ProgramWorkingDirectoryPath._validated(String value) =
      _ProgramWorkingDirectoryPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramArguments
    with _$ProgramArguments
    implements StringDomainValueObject {
  const ProgramArguments._();

  factory ProgramArguments(String value) => ProgramArguments._validated(value);

  const factory ProgramArguments._validated(String value) = _ProgramArguments;

  static const empty = ProgramArguments._validated('');
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRunArguments
    with _$ProgramRunArguments, IterableMixin<String>
    implements DomainValueObject<List<String>> {
  const ProgramRunArguments._();

  factory ProgramRunArguments(Iterable<String> arguments) =>
      ProgramRunArguments._validated(
        arguments: List<String>.unmodifiable(arguments),
      );

  const factory ProgramRunArguments._validated({
    required List<String> arguments,
  }) = _ProgramRunArguments;

  @override
  List<String> get value => arguments;

  @override
  Iterator<String> get iterator => value.iterator;

  String operator [](int index) => value[index];
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PathOpenTarget
    with _$PathOpenTarget
    implements StringDomainValueObject {
  const PathOpenTarget._();

  factory PathOpenTarget(String value) => PathOpenTarget._validated(
    _requiredValueObjectString(value, 'pathOpenTarget'),
  );

  const factory PathOpenTarget._validated(String value) = _PathOpenTarget;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PathRevealTarget
    with _$PathRevealTarget
    implements StringDomainValueObject {
  const PathRevealTarget._();

  factory PathRevealTarget(String value) => PathRevealTarget._validated(
    _requiredValueObjectString(value, 'pathRevealTarget'),
  );

  const factory PathRevealTarget._validated(String value) = _PathRevealTarget;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramLocale
    with _$ProgramLocale
    implements StringDomainValueObject {
  const ProgramLocale._();

  factory ProgramLocale(String value) => ProgramLocale._validated(value);

  const factory ProgramLocale._validated(String value) = _ProgramLocale;

  static const empty = ProgramLocale._validated('');
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramLogPath
    with _$ProgramLogPath
    implements StringDomainValueObject {
  const ProgramLogPath._();

  factory ProgramLogPath(String value) =>
      ProgramLogPath._validated(value.trim());

  const factory ProgramLogPath._validated(String value) = _ProgramLogPath;

  static const empty = ProgramLogPath._validated('');
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramLogFileName
    with _$ProgramLogFileName
    implements StringDomainValueObject {
  const ProgramLogFileName._();

  factory ProgramLogFileName(String value) => ProgramLogFileName._validated(
    _requiredValueObjectString(value, 'programLogFileName'),
  );

  const factory ProgramLogFileName._validated(String value) =
      _ProgramLogFileName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineDebugChannels
    with _$WineDebugChannels
    implements StringDomainValueObject {
  const WineDebugChannels._();

  factory WineDebugChannels(String value) =>
      WineDebugChannels._validated(value.trim());

  const factory WineDebugChannels._validated(String value) = _WineDebugChannels;

  static const empty = WineDebugChannels._validated('');
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRegistryKey
    with _$ProgramRegistryKey
    implements StringDomainValueObject {
  const ProgramRegistryKey._();

  factory ProgramRegistryKey(String value) => ProgramRegistryKey._validated(
    _requiredValueObjectString(value, 'programRegistryKey'),
  );

  const factory ProgramRegistryKey._validated(String value) =
      _ProgramRegistryKey;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRegistryValueName
    with _$ProgramRegistryValueName
    implements StringDomainValueObject {
  const ProgramRegistryValueName._();

  factory ProgramRegistryValueName(String value) =>
      ProgramRegistryValueName._validated(
        _requiredValueObjectString(value, 'programRegistryValueName'),
      );

  const factory ProgramRegistryValueName._validated(String value) =
      _ProgramRegistryValueName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRegistryValueType
    with _$ProgramRegistryValueType
    implements StringDomainValueObject {
  const ProgramRegistryValueType._();

  factory ProgramRegistryValueType(String value) =>
      ProgramRegistryValueType._validated(
        _requiredValueObjectString(value, 'programRegistryValueType'),
      );

  const factory ProgramRegistryValueType._validated(String value) =
      _ProgramRegistryValueType;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRegistryValueData
    with _$ProgramRegistryValueData
    implements StringDomainValueObject {
  const ProgramRegistryValueData._();

  factory ProgramRegistryValueData(String value) =>
      ProgramRegistryValueData._validated(
        _requiredValueObjectString(value, 'programRegistryValueData'),
      );

  const factory ProgramRegistryValueData._validated(String value) =
      _ProgramRegistryValueData;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinedbgCommand
    with _$WinedbgCommand
    implements StringDomainValueObject {
  const WinedbgCommand._();

  factory WinedbgCommand(String value) => WinedbgCommand._validated(
    _requiredValueObjectString(value, 'winedbgCommand'),
  );

  const factory WinedbgCommand._validated(String value) = _WinedbgCommand;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramEnvironmentVariableName
    with _$ProgramEnvironmentVariableName
    implements StringDomainValueObject {
  const ProgramEnvironmentVariableName._();

  factory ProgramEnvironmentVariableName(String value) =>
      ProgramEnvironmentVariableName._validated(
        _requiredEnvironmentVariableValueObjectName(value),
      );

  const factory ProgramEnvironmentVariableName._validated(String value) =
      _ProgramEnvironmentVariableName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramEnvironmentVariableValue
    with _$ProgramEnvironmentVariableValue
    implements StringDomainValueObject {
  const ProgramEnvironmentVariableValue._();

  factory ProgramEnvironmentVariableValue(String value) =>
      ProgramEnvironmentVariableValue._validated(value);

  const factory ProgramEnvironmentVariableValue._validated(String value) =
      _ProgramEnvironmentVariableValue;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramSource
    with _$ProgramSource
    implements StringDomainValueObject {
  const ProgramSource._();

  factory ProgramSource(String value) => ProgramSource._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'programSource',
      allowedValues: allowedValues,
    ),
  );

  const factory ProgramSource._validated(String value) = _ProgramSource;

  static const allowedValues = <String>{
    'globalStartMenu',
    'userStartMenu',
    'pinned',
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramArchitecture
    with _$ProgramArchitecture
    implements StringDomainValueObject {
  const ProgramArchitecture._();

  factory ProgramArchitecture(String value) => ProgramArchitecture._validated(
    _requiredValueObjectString(value, 'programArchitecture'),
  );

  const factory ProgramArchitecture._validated(String value) =
      _ProgramArchitecture;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramFileDescription
    with _$ProgramFileDescription
    implements StringDomainValueObject {
  const ProgramFileDescription._();

  factory ProgramFileDescription(String value) =>
      ProgramFileDescription._validated(
        _requiredValueObjectString(value, 'programFileDescription'),
      );

  const factory ProgramFileDescription._validated(String value) =
      _ProgramFileDescription;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramProductName
    with _$ProgramProductName
    implements StringDomainValueObject {
  const ProgramProductName._();

  factory ProgramProductName(String value) => ProgramProductName._validated(
    _requiredValueObjectString(value, 'programProductName'),
  );

  const factory ProgramProductName._validated(String value) =
      _ProgramProductName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramCompanyName
    with _$ProgramCompanyName
    implements StringDomainValueObject {
  const ProgramCompanyName._();

  factory ProgramCompanyName(String value) => ProgramCompanyName._validated(
    _requiredValueObjectString(value, 'programCompanyName'),
  );

  const factory ProgramCompanyName._validated(String value) =
      _ProgramCompanyName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramFileVersion
    with _$ProgramFileVersion
    implements StringDomainValueObject {
  const ProgramFileVersion._();

  factory ProgramFileVersion(String value) => ProgramFileVersion._validated(
    _requiredValueObjectString(value, 'programFileVersion'),
  );

  const factory ProgramFileVersion._validated(String value) =
      _ProgramFileVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramProductVersion
    with _$ProgramProductVersion
    implements StringDomainValueObject {
  const ProgramProductVersion._();

  factory ProgramProductVersion(String value) =>
      ProgramProductVersion._validated(
        _requiredValueObjectString(value, 'programProductVersion'),
      );

  const factory ProgramProductVersion._validated(String value) =
      _ProgramProductVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramLauncherId
    with _$ProgramLauncherId
    implements StringDomainValueObject {
  const ProgramLauncherId._();

  factory ProgramLauncherId(String value) => ProgramLauncherId._validated(
    _requiredValueObjectString(value, 'programLauncherId'),
  );

  const factory ProgramLauncherId._validated(String value) = _ProgramLauncherId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessId
    with _$WineProcessId
    implements StringDomainValueObject {
  const WineProcessId._();

  factory WineProcessId(String value) => WineProcessId._validated(
    _requiredValueObjectString(value, 'wineProcessId'),
  );

  const factory WineProcessId._validated(String value) = _WineProcessId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessStatus
    with _$WineProcessStatus
    implements StringDomainValueObject {
  const WineProcessStatus._();

  factory WineProcessStatus(String value) => WineProcessStatus._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'wineProcessStatus',
      allowedValues: allowedValues,
    ),
  );

  const factory WineProcessStatus._validated(String value) = _WineProcessStatus;

  static const allowedValues = <String>{'terminated', 'failed'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RunnerKind with _$RunnerKind implements StringDomainValueObject {
  const RunnerKind._();

  factory RunnerKind(String value) =>
      RunnerKind._validated(_requiredValueObjectString(value, 'runnerKind'));

  const factory RunnerKind._validated(String value) = _RunnerKind;

  static const wine = RunnerKind._validated('wine');
  static const wineRegistry = RunnerKind._validated('wineRegistry');
  static const wineRegistryQuery = RunnerKind._validated('wineRegistryQuery');
  static const wineboot = RunnerKind._validated('wineboot');
  static const wineserver = RunnerKind._validated('wineserver');
  static const winedbg = RunnerKind._validated('winedbg');
  static const winetricks = RunnerKind._validated('winetricks');
  static const terminal = RunnerKind._validated('terminal');
  static const macosWine = RunnerKind._validated('macosWine');
  static const macosWineRegistry = RunnerKind._validated('macosWineRegistry');
  static const macosWineRegistryQuery = RunnerKind._validated(
    'macosWineRegistryQuery',
  );
  static const macosWineserver = RunnerKind._validated('macosWineserver');
  static const macosWinedbg = RunnerKind._validated('macosWinedbg');
  static const macosWinetricks = RunnerKind._validated('macosWinetricks');
  static const macosTerminal = RunnerKind._validated('macosTerminal');

  static const stableRequestKinds = <RunnerKind>[
    wine,
    wineRegistry,
    wineRegistryQuery,
    wineboot,
    wineserver,
    winedbg,
    winetricks,
    terminal,
    macosWine,
    macosWineRegistry,
    macosWineRegistryQuery,
    macosWineserver,
    macosWinedbg,
    macosWinetricks,
    macosTerminal,
  ];
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCommand
    with _$BottleCommand
    implements StringDomainValueObject {
  const BottleCommand._();

  factory BottleCommand(String value) => BottleCommand._validated(
    _requiredValueObjectString(value, 'bottleCommand'),
  );

  const factory BottleCommand._validated(String value) = _BottleCommand;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleLocation
    with _$BottleLocation
    implements StringDomainValueObject {
  const BottleLocation._();

  factory BottleLocation(String value) => BottleLocation._validated(
    _requiredValueObjectString(value, 'bottleLocation'),
  );

  const factory BottleLocation._validated(String value) = _BottleLocation;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksVerbId
    with _$WinetricksVerbId
    implements StringDomainValueObject {
  const WinetricksVerbId._();

  factory WinetricksVerbId(String value) => WinetricksVerbId._validated(
    _requiredValueObjectString(value, 'winetricksVerbId'),
  );

  const factory WinetricksVerbId._validated(String value) = _WinetricksVerbId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksVerbName
    with _$WinetricksVerbName
    implements StringDomainValueObject {
  const WinetricksVerbName._();

  factory WinetricksVerbName(String value) => WinetricksVerbName._validated(
    _requiredValueObjectString(value, 'winetricksVerbName'),
  );

  const factory WinetricksVerbName._validated(String value) =
      _WinetricksVerbName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksVerbDescription
    with _$WinetricksVerbDescription
    implements StringDomainValueObject {
  const WinetricksVerbDescription._();

  factory WinetricksVerbDescription(String value) =>
      WinetricksVerbDescription._validated(value.trim());

  const factory WinetricksVerbDescription._validated(String value) =
      _WinetricksVerbDescription;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksCategoryId
    with _$WinetricksCategoryId
    implements StringDomainValueObject {
  const WinetricksCategoryId._();

  factory WinetricksCategoryId(String value) => WinetricksCategoryId._validated(
    _requiredValueObjectString(value, 'winetricksCategoryId'),
  );

  const factory WinetricksCategoryId._validated(String value) =
      _WinetricksCategoryId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksCategoryName
    with _$WinetricksCategoryName
    implements StringDomainValueObject {
  const WinetricksCategoryName._();

  factory WinetricksCategoryName(String value) =>
      WinetricksCategoryName._validated(
        _requiredValueObjectString(value, 'winetricksCategoryName'),
      );

  const factory WinetricksCategoryName._validated(String value) =
      _WinetricksCategoryName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class GraphicsBackendKind
    with _$GraphicsBackendKind
    implements StringDomainValueObject {
  const GraphicsBackendKind._();

  factory GraphicsBackendKind(String value) => GraphicsBackendKind._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'graphicsBackend',
      allowedValues: allowedValues,
    ),
  );

  const factory GraphicsBackendKind._validated(String value) =
      _GraphicsBackendKind;

  static const allowedValues = <String>{
    'wineDefault',
    'dxvk',
    'dxmt',
    'd3dMetal',
    'vkd3dProton',
  };
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class GraphicsBackendSignalKind
    with _$GraphicsBackendSignalKind
    implements StringDomainValueObject {
  const GraphicsBackendSignalKind._();

  factory GraphicsBackendSignalKind(String value) =>
      GraphicsBackendSignalKind._validated(
        _requiredAllowedValueObjectString(
          value: value,
          fieldName: 'graphicsBackendSignalKind',
          allowedValues: allowedValues,
        ),
      );

  const factory GraphicsBackendSignalKind._validated(String value) =
      _GraphicsBackendSignalKind;

  static const allowedValues = <String>{'peImport', 'string'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class GraphicsBackendSignalValue
    with _$GraphicsBackendSignalValue
    implements StringDomainValueObject {
  const GraphicsBackendSignalValue._();

  factory GraphicsBackendSignalValue(String value) =>
      GraphicsBackendSignalValue._validated(
        _requiredValueObjectString(value, 'graphicsBackendSignalValue'),
      );

  const factory GraphicsBackendSignalValue._validated(String value) =
      _GraphicsBackendSignalValue;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class GraphicsBackendConfidence
    with _$GraphicsBackendConfidence
    implements StringDomainValueObject {
  const GraphicsBackendConfidence._();

  factory GraphicsBackendConfidence(String value) =>
      GraphicsBackendConfidence._validated(
        _requiredAllowedValueObjectString(
          value: value,
          fieldName: 'graphicsBackendConfidence',
          allowedValues: allowedValues,
        ),
      );

  const factory GraphicsBackendConfidence._validated(String value) =
      _GraphicsBackendConfidence;

  static const allowedValues = <String>{'low', 'medium', 'high'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeId with _$RuntimeId implements StringDomainValueObject {
  const RuntimeId._();

  factory RuntimeId(String value) =>
      RuntimeId._validated(_requiredValueObjectString(value, 'runtimeId'));

  const factory RuntimeId._validated(String value) = _RuntimeId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeName
    with _$RuntimeName
    implements StringDomainValueObject {
  const RuntimeName._();

  factory RuntimeName(String value) =>
      RuntimeName._validated(_requiredValueObjectString(value, 'runtimeName'));

  const factory RuntimeName._validated(String value) = _RuntimeName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimePlatformName
    with _$RuntimePlatformName
    implements StringDomainValueObject {
  const RuntimePlatformName._();

  factory RuntimePlatformName(String value) => RuntimePlatformName._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'runtimePlatform',
      allowedValues: allowedValues,
    ),
  );

  const factory RuntimePlatformName._validated(String value) =
      _RuntimePlatformName;

  static const allowedValues = <String>{'macos', 'linux'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeArchitecture
    with _$RuntimeArchitecture
    implements StringDomainValueObject {
  const RuntimeArchitecture._();

  factory RuntimeArchitecture(String value) => RuntimeArchitecture._validated(
    _requiredValueObjectString(value, 'runtimeArchitecture'),
  );

  const factory RuntimeArchitecture._validated(String value) =
      _RuntimeArchitecture;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeDistributionKind
    with _$RuntimeDistributionKind
    implements StringDomainValueObject {
  const RuntimeDistributionKind._();

  factory RuntimeDistributionKind(String value) =>
      RuntimeDistributionKind._validated(
        _requiredAllowedValueObjectString(
          value: value,
          fieldName: 'runtimeDistributionKind',
          allowedValues: allowedValues,
        ),
      );

  const factory RuntimeDistributionKind._validated(String value) =
      _RuntimeDistributionKind;

  static const allowedValues = <String>{'bootstrap', 'development', 'managed'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackId
    with _$RuntimeStackId
    implements StringDomainValueObject {
  const RuntimeStackId._();

  factory RuntimeStackId(String value) => RuntimeStackId._validated(
    _requiredValueObjectString(value, 'runtimeStackId'),
  );

  const factory RuntimeStackId._validated(String value) = _RuntimeStackId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackName
    with _$RuntimeStackName
    implements StringDomainValueObject {
  const RuntimeStackName._();

  factory RuntimeStackName(String value) => RuntimeStackName._validated(
    _requiredValueObjectString(value, 'runtimeStackName'),
  );

  const factory RuntimeStackName._validated(String value) = _RuntimeStackName;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeCompatibilityTarget
    with _$RuntimeCompatibilityTarget
    implements StringDomainValueObject {
  const RuntimeCompatibilityTarget._();

  factory RuntimeCompatibilityTarget(String value) =>
      RuntimeCompatibilityTarget._validated(
        _requiredValueObjectString(value, 'runtimeCompatibilityTarget'),
      );

  const factory RuntimeCompatibilityTarget._validated(String value) =
      _RuntimeCompatibilityTarget;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeComponentId
    with _$RuntimeComponentId
    implements StringDomainValueObject {
  const RuntimeComponentId._();

  factory RuntimeComponentId(String value) => RuntimeComponentId._validated(
    _requiredValueObjectString(value, 'runtimeComponentId'),
  );

  const factory RuntimeComponentId._validated(String value) =
      _RuntimeComponentId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeBackendId
    with _$RuntimeBackendId
    implements StringDomainValueObject {
  const RuntimeBackendId._();

  factory RuntimeBackendId(String value) => RuntimeBackendId._validated(
    _requiredValueObjectString(value, 'runtimeBackendId'),
  );

  const factory RuntimeBackendId._validated(String value) = _RuntimeBackendId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeRole
    with _$RuntimeRole
    implements StringDomainValueObject {
  const RuntimeRole._();

  factory RuntimeRole(String value) =>
      RuntimeRole._validated(_requiredValueObjectString(value, 'runtimeRole'));

  const factory RuntimeRole._validated(String value) = _RuntimeRole;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeComponentPath
    with _$RuntimeComponentPath
    implements StringDomainValueObject {
  const RuntimeComponentPath._();

  factory RuntimeComponentPath(String value) => RuntimeComponentPath._validated(
    _requiredValueObjectString(value, 'runtimeComponentPath'),
  );

  const factory RuntimeComponentPath._validated(String value) =
      _RuntimeComponentPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeRootPath
    with _$RuntimeRootPath
    implements StringDomainValueObject {
  const RuntimeRootPath._();

  factory RuntimeRootPath(String value) => RuntimeRootPath._validated(
    _requiredValueObjectString(value, 'runtimeRootPath'),
  );

  const factory RuntimeRootPath._validated(String value) = _RuntimeRootPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeMissingPath
    with _$RuntimeMissingPath
    implements StringDomainValueObject {
  const RuntimeMissingPath._();

  factory RuntimeMissingPath(String value) => RuntimeMissingPath._validated(
    _requiredValueObjectString(value, 'runtimeMissingPath'),
  );

  const factory RuntimeMissingPath._validated(String value) =
      _RuntimeMissingPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeArchivePath
    with _$RuntimeArchivePath
    implements StringDomainValueObject {
  const RuntimeArchivePath._();

  factory RuntimeArchivePath(String value) => RuntimeArchivePath._validated(
    _requiredValueObjectString(value, 'runtimeArchivePath'),
  );

  const factory RuntimeArchivePath._validated(String value) =
      _RuntimeArchivePath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeArchiveUrl
    with _$RuntimeArchiveUrl
    implements StringDomainValueObject {
  const RuntimeArchiveUrl._();

  factory RuntimeArchiveUrl(String value) => RuntimeArchiveUrl._validated(
    _requiredValueObjectString(value, 'runtimeArchiveUrl'),
  );

  const factory RuntimeArchiveUrl._validated(String value) = _RuntimeArchiveUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeVersionUrl
    with _$RuntimeVersionUrl
    implements StringDomainValueObject {
  const RuntimeVersionUrl._();

  factory RuntimeVersionUrl(String value) => RuntimeVersionUrl._validated(
    _requiredValueObjectString(value, 'runtimeVersionUrl'),
  );

  const factory RuntimeVersionUrl._validated(String value) = _RuntimeVersionUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceManifestPath
    with _$RuntimeSourceManifestPath
    implements StringDomainValueObject {
  const RuntimeSourceManifestPath._();

  factory RuntimeSourceManifestPath(String value) =>
      RuntimeSourceManifestPath._validated(
        _requiredValueObjectString(value, 'runtimeSourceManifestPath'),
      );

  const factory RuntimeSourceManifestPath._validated(String value) =
      _RuntimeSourceManifestPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceManifestUrl
    with _$RuntimeSourceManifestUrl
    implements StringDomainValueObject {
  const RuntimeSourceManifestUrl._();

  factory RuntimeSourceManifestUrl(String value) =>
      RuntimeSourceManifestUrl._validated(
        _requiredValueObjectString(value, 'runtimeSourceManifestUrl'),
      );

  const factory RuntimeSourceManifestUrl._validated(String value) =
      _RuntimeSourceManifestUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceManifestSignaturePath
    with _$RuntimeSourceManifestSignaturePath
    implements StringDomainValueObject {
  const RuntimeSourceManifestSignaturePath._();

  factory RuntimeSourceManifestSignaturePath(String value) =>
      RuntimeSourceManifestSignaturePath._validated(
        _requiredValueObjectString(value, 'runtimeSourceManifestSignaturePath'),
      );

  const factory RuntimeSourceManifestSignaturePath._validated(String value) =
      _RuntimeSourceManifestSignaturePath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceManifestSignatureUrl
    with _$RuntimeSourceManifestSignatureUrl
    implements StringDomainValueObject {
  const RuntimeSourceManifestSignatureUrl._();

  factory RuntimeSourceManifestSignatureUrl(String value) =>
      RuntimeSourceManifestSignatureUrl._validated(
        _requiredValueObjectString(value, 'runtimeSourceManifestSignatureUrl'),
      );

  const factory RuntimeSourceManifestSignatureUrl._validated(String value) =
      _RuntimeSourceManifestSignatureUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeArchiveChecksumValue
    with _$RuntimeArchiveChecksumValue
    implements StringDomainValueObject {
  const RuntimeArchiveChecksumValue._();

  factory RuntimeArchiveChecksumValue(String value) =>
      RuntimeArchiveChecksumValue._validated(
        _requiredValueObjectString(value, 'runtimeArchiveChecksum'),
      );

  const factory RuntimeArchiveChecksumValue._validated(String value) =
      _RuntimeArchiveChecksumValue;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeVersion
    with _$RuntimeVersion
    implements StringDomainValueObject {
  const RuntimeVersion._();

  factory RuntimeVersion(String value) => RuntimeVersion._validated(
    _requiredValueObjectString(value, 'runtimeVersion'),
  );

  const factory RuntimeVersion._validated(String value) = _RuntimeVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeInstallProgressStage
    with _$RuntimeInstallProgressStage
    implements StringDomainValueObject {
  const RuntimeInstallProgressStage._();

  factory RuntimeInstallProgressStage(String value) =>
      RuntimeInstallProgressStage._validated(
        _requiredValueObjectString(value, 'runtimeInstallProgressStage'),
      );

  const factory RuntimeInstallProgressStage._validated(String value) =
      _RuntimeInstallProgressStage;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeInstallProgressFraction
    with _$RuntimeInstallProgressFraction
    implements DoubleDomainValueObject {
  const RuntimeInstallProgressFraction._();

  factory RuntimeInstallProgressFraction(num value) =>
      RuntimeInstallProgressFraction._validated(
        _requiredFractionValueObjectDouble(
          value,
          'runtimeInstallProgressFraction',
        ),
      );

  const factory RuntimeInstallProgressFraction._validated(double value) =
      _RuntimeInstallProgressFraction;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeRelativePath
    with _$RuntimeRelativePath
    implements DomainValueObject<List<String>> {
  const RuntimeRelativePath._();

  factory RuntimeRelativePath(Iterable<String> components) =>
      RuntimeRelativePath._validated(
        components: _requiredRuntimeRelativePathComponents(components),
      );

  const factory RuntimeRelativePath._validated({
    required List<String> components,
  }) = _RuntimeRelativePath;

  @override
  List<String> get value => components;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceComponentId
    with _$RuntimeSourceComponentId
    implements StringDomainValueObject {
  const RuntimeSourceComponentId._();

  factory RuntimeSourceComponentId(String value) =>
      RuntimeSourceComponentId._validated(
        _requiredValueObjectString(value, 'runtimeSourceComponentId'),
      );

  const factory RuntimeSourceComponentId._validated(String value) =
      _RuntimeSourceComponentId;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSourceComponentVersion
    with _$RuntimeSourceComponentVersion
    implements StringDomainValueObject {
  const RuntimeSourceComponentVersion._();

  factory RuntimeSourceComponentVersion(String value) =>
      RuntimeSourceComponentVersion._validated(
        _requiredValueObjectString(value, 'runtimeSourceComponentVersion'),
      );

  const factory RuntimeSourceComponentVersion._validated(String value) =
      _RuntimeSourceComponentVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class UpdateCheckStatus
    with _$UpdateCheckStatus
    implements StringDomainValueObject {
  const UpdateCheckStatus._();

  factory UpdateCheckStatus(String value) => UpdateCheckStatus._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'updateCheckStatus',
      allowedValues: allowedValues,
    ),
  );

  const factory UpdateCheckStatus._validated(String value) = _UpdateCheckStatus;

  static const allowedValues = <String>{'unknown', 'current', 'available'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class UpdateInstallStatus
    with _$UpdateInstallStatus
    implements StringDomainValueObject {
  const UpdateInstallStatus._();

  factory UpdateInstallStatus(String value) => UpdateInstallStatus._validated(
    _requiredAllowedValueObjectString(
      value: value,
      fieldName: 'updateInstallStatus',
      allowedValues: allowedValues,
    ),
  );

  const factory UpdateInstallStatus._validated(String value) =
      _UpdateInstallStatus;

  static const allowedValues = <String>{'skipped', 'installed'};
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppVersion with _$AppVersion implements StringDomainValueObject {
  const AppVersion._();

  factory AppVersion(String value) =>
      AppVersion._validated(_requiredValueObjectString(value, 'appVersion'));

  const factory AppVersion._validated(String value) = _AppVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ReleaseVersion
    with _$ReleaseVersion
    implements StringDomainValueObject {
  const ReleaseVersion._();

  factory ReleaseVersion(String value) => ReleaseVersion._validated(
    _requiredValueObjectString(value, 'releaseVersion'),
  );

  const factory ReleaseVersion._validated(String value) = _ReleaseVersion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppArchiveUrl
    with _$AppArchiveUrl
    implements StringDomainValueObject {
  const AppArchiveUrl._();

  factory AppArchiveUrl(String value) => AppArchiveUrl._validated(
    _requiredValueObjectString(value, 'appArchiveUrl'),
  );

  const factory AppArchiveUrl._validated(String value) = _AppArchiveUrl;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppArchiveSha256
    with _$AppArchiveSha256
    implements StringDomainValueObject {
  const AppArchiveSha256._();

  factory AppArchiveSha256(String value) => AppArchiveSha256._validated(
    _requiredValueObjectString(value, 'appArchiveSha256'),
  );

  const factory AppArchiveSha256._validated(String value) = _AppArchiveSha256;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppInstallPath
    with _$AppInstallPath
    implements StringDomainValueObject {
  const AppInstallPath._();

  factory AppInstallPath(String value) => AppInstallPath._validated(
    _requiredValueObjectString(value, 'appInstallPath'),
  );

  const factory AppInstallPath._validated(String value) = _AppInstallPath;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class DefaultBottlePath
    with _$DefaultBottlePath
    implements StringDomainValueObject {
  const DefaultBottlePath._();

  factory DefaultBottlePath(String value) => DefaultBottlePath._validated(
    _requiredValueObjectString(value, 'defaultBottlePath'),
  );

  const factory DefaultBottlePath._validated(String value) = _DefaultBottlePath;
}

String _requiredValueObjectString(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return value;
}

String _requiredIdentifierValueObjectString(String value, String fieldName) {
  final checked = _requiredValueObjectString(value, fieldName);
  if (!RegExp(r'^[a-z0-9][a-z0-9_.-]*$').hasMatch(checked)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be a lowercase identifier',
    );
  }
  return checked;
}

String _requiredAllowedValueObjectString({
  required String value,
  required String fieldName,
  required Set<String> allowedValues,
}) {
  if (!allowedValues.contains(value)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be one of $allowedValues',
    );
  }
  return value;
}

int _requiredBoundedValueObjectInt({
  required int value,
  required String fieldName,
  required int minimum,
  required int maximum,
  Option<int> step = const Option.none(),
}) {
  if (value < minimum || value > maximum) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be between $minimum and $maximum',
    );
  }

  step.match(() {}, (requiredStep) {
    if ((value - minimum) % requiredStep != 0) {
      throw ArgumentError.value(
        value,
        fieldName,
        'must use step $requiredStep from $minimum',
      );
    }
  });

  return value;
}

double _requiredFractionValueObjectDouble(num value, String fieldName) {
  final normalized = value.toDouble();
  if (normalized.isNaN || normalized.isInfinite) {
    throw ArgumentError.value(value, fieldName, 'must be finite');
  }
  if (normalized < 0 || normalized > 1) {
    throw ArgumentError.value(value, fieldName, 'must be between 0 and 1');
  }
  return normalized;
}

List<String> _requiredRuntimeRelativePathComponents(
  Iterable<String> components,
) {
  final validatedComponents = List<String>.unmodifiable(
    components.map(
      (component) =>
          _requiredValueObjectString(component, 'runtimeRelativePath'),
    ),
  );
  if (validatedComponents.isEmpty) {
    throw ArgumentError.value(components, 'runtimeRelativePath');
  }
  return validatedComponents;
}

String _requiredEnvironmentVariableValueObjectName(String value) {
  final name = _requiredValueObjectString(value, 'environment variable name');
  if (name.contains('=')) {
    throw ArgumentError.value(value, 'environment variable name');
  }
  return name;
}
