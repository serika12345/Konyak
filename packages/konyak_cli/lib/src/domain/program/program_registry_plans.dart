import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_runtime_settings_models.dart';
import '../shared/domain_value_objects.dart';
import 'program_registry_models.dart';

List<RegistryValueUpdate> windowsVersionRegistryUpdates(
  WindowsVersion windowsVersion,
) {
  return <RegistryValueUpdate>[
    RegistryValueUpdate(
      key: ProgramRegistryKey(r'HKCU\Software\Wine'),
      name: ProgramRegistryValueName('Version'),
      type: ProgramRegistryValueType('REG_SZ'),
      data: ProgramRegistryValueData(windowsVersion.value),
    ),
  ];
}

List<RegistryValueUpdate> runtimeSettingsRegistryUpdates({
  required BottleRuntimeSettings currentRuntimeSettings,
  required BottleRuntimeSettings runtimeSettings,
  required bool includeMacDriverSettings,
}) {
  final effectiveRuntimeSettings = includeMacDriverSettings
      ? runtimeSettings.withHighResolutionModeWindowsDpiAdjustment(
          currentRuntimeSettings,
        )
      : runtimeSettings;

  final buildVersionUpdates =
      effectiveRuntimeSettings.buildVersion !=
          currentRuntimeSettings.buildVersion
      ? <RegistryValueUpdate>[
          ..._windowsVersionForBuildVersion(
            effectiveRuntimeSettings.buildVersion.value,
          ).match(
            () => const <RegistryValueUpdate>[],
            windowsVersionRegistryUpdates,
          ),
          RegistryValueUpdate(
            key: ProgramRegistryKey(
              r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
            ),
            name: ProgramRegistryValueName('CurrentBuild'),
            type: ProgramRegistryValueType('REG_SZ'),
            data: ProgramRegistryValueData(
              effectiveRuntimeSettings.buildVersion.value.toString(),
            ),
          ),
          RegistryValueUpdate(
            key: ProgramRegistryKey(
              r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
            ),
            name: ProgramRegistryValueName('CurrentBuildNumber'),
            type: ProgramRegistryValueType('REG_SZ'),
            data: ProgramRegistryValueData(
              effectiveRuntimeSettings.buildVersion.value.toString(),
            ),
          ),
        ]
      : const <RegistryValueUpdate>[];

  final retinaModeUpdates =
      includeMacDriverSettings &&
          effectiveRuntimeSettings.retinaMode !=
              currentRuntimeSettings.retinaMode
      ? <RegistryValueUpdate>[
          RegistryValueUpdate(
            key: ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver'),
            name: ProgramRegistryValueName('RetinaMode'),
            type: ProgramRegistryValueType('REG_SZ'),
            data: ProgramRegistryValueData(
              switch (effectiveRuntimeSettings.retinaMode) {
                true => 'y',
                false => 'n',
              },
            ),
          ),
        ]
      : const <RegistryValueUpdate>[];

  final dpiScalingUpdates =
      effectiveRuntimeSettings.dpiScaling != currentRuntimeSettings.dpiScaling
      ? <RegistryValueUpdate>[
          RegistryValueUpdate(
            key: ProgramRegistryKey(r'HKCU\Control Panel\Desktop'),
            name: ProgramRegistryValueName('LogPixels'),
            type: ProgramRegistryValueType('REG_DWORD'),
            data: ProgramRegistryValueData(
              effectiveRuntimeSettings.dpiScaling.value.toString(),
            ),
          ),
        ]
      : const <RegistryValueUpdate>[];

  return List.unmodifiable(<RegistryValueUpdate>[
    ...buildVersionUpdates,
    ...retinaModeUpdates,
    ...dpiScalingUpdates,
  ]);
}

Option<WindowsVersion> _windowsVersionForBuildVersion(int buildVersion) {
  if (buildVersion >= 22000) {
    return Option.of(WindowsVersion('win11'));
  }
  if (buildVersion >= 10000) {
    return Option.of(WindowsVersion('win10'));
  }
  if (buildVersion >= 9600) {
    return Option.of(WindowsVersion('win81'));
  }
  if (buildVersion >= 9200) {
    return Option.of(WindowsVersion('win8'));
  }
  if (buildVersion >= 7600) {
    return Option.of(WindowsVersion('win7'));
  }
  if (buildVersion >= 3790) {
    return Option.of(WindowsVersion('winxp64'));
  }

  return const Option.none();
}

List<RegistryValueQuery> bottleSettingsRegistryQueries({
  required bool includeMacDriverSettings,
}) {
  return <RegistryValueQuery>[
    RegistryValueQuery(
      key: ProgramRegistryKey(r'HKCU\Software\Wine'),
      name: ProgramRegistryValueName('Version'),
    ),
    RegistryValueQuery(
      key: ProgramRegistryKey(
        r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
      ),
      name: ProgramRegistryValueName('CurrentBuild'),
    ),
    if (includeMacDriverSettings)
      RegistryValueQuery(
        key: ProgramRegistryKey(r'HKCU\Software\Wine\Mac Driver'),
        name: ProgramRegistryValueName('RetinaMode'),
      ),
    RegistryValueQuery(
      key: ProgramRegistryKey(r'HKCU\Control Panel\Desktop'),
      name: ProgramRegistryValueName('LogPixels'),
    ),
  ];
}

ProgramRunArguments registryUpdateArguments(RegistryValueUpdate update) {
  return ProgramRunArguments(<String>[
    'reg',
    'add',
    update.key.value,
    '-v',
    update.name.value,
    '-t',
    update.type.value,
    '-d',
    update.data.value,
    '-f',
  ]);
}

ProgramRunArguments registryQueryArguments(RegistryValueQuery query) {
  return ProgramRunArguments(<String>[
    'reg',
    'query',
    query.key.value,
    '/v',
    query.name.value,
  ]);
}
