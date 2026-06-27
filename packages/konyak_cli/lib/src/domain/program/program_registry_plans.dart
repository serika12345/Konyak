part of '../../../konyak_cli.dart';

List<_RegistryValueUpdate> _windowsVersionRegistryUpdates(
  String windowsVersion,
) {
  return <_RegistryValueUpdate>[
    _RegistryValueUpdate(
      key: r'HKCU\Software\Wine',
      name: 'Version',
      type: 'REG_SZ',
      data: windowsVersion,
    ),
  ];
}

List<_RegistryValueUpdate> _runtimeSettingsRegistryUpdates({
  required BottleRuntimeSettings currentRuntimeSettings,
  required BottleRuntimeSettings runtimeSettings,
  required bool includeMacDriverSettings,
}) {
  final updates = <_RegistryValueUpdate>[];
  final effectiveRuntimeSettings = includeMacDriverSettings
      ? runtimeSettings.withHighResolutionModeWindowsDpiAdjustment(
          currentRuntimeSettings,
        )
      : runtimeSettings;

  if (effectiveRuntimeSettings.buildVersion !=
      currentRuntimeSettings.buildVersion) {
    final windowsVersion = _windowsVersionForBuildVersion(
      effectiveRuntimeSettings.buildVersion.value,
    );
    windowsVersion.match(() {}, (version) {
      updates.addAll(_windowsVersionRegistryUpdates(version));
    });

    updates
      ..add(
        _RegistryValueUpdate(
          key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
          name: 'CurrentBuild',
          type: 'REG_SZ',
          data: effectiveRuntimeSettings.buildVersion.value.toString(),
        ),
      )
      ..add(
        _RegistryValueUpdate(
          key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
          name: 'CurrentBuildNumber',
          type: 'REG_SZ',
          data: effectiveRuntimeSettings.buildVersion.value.toString(),
        ),
      );
  }

  if (includeMacDriverSettings &&
      effectiveRuntimeSettings.retinaMode !=
          currentRuntimeSettings.retinaMode) {
    updates.add(
      _RegistryValueUpdate(
        key: r'HKCU\Software\Wine\Mac Driver',
        name: 'RetinaMode',
        type: 'REG_SZ',
        data: effectiveRuntimeSettings.retinaMode ? 'y' : 'n',
      ),
    );
  }

  if (effectiveRuntimeSettings.dpiScaling !=
      currentRuntimeSettings.dpiScaling) {
    updates.add(
      _RegistryValueUpdate(
        key: r'HKCU\Control Panel\Desktop',
        name: 'LogPixels',
        type: 'REG_DWORD',
        data: effectiveRuntimeSettings.dpiScaling.value.toString(),
      ),
    );
  }

  return List.unmodifiable(updates);
}

Option<String> _windowsVersionForBuildVersion(int buildVersion) {
  if (buildVersion >= 22000) {
    return Option.of('win11');
  }
  if (buildVersion >= 10000) {
    return Option.of('win10');
  }
  if (buildVersion >= 9600) {
    return Option.of('win81');
  }
  if (buildVersion >= 9200) {
    return Option.of('win8');
  }
  if (buildVersion >= 7600) {
    return Option.of('win7');
  }
  if (buildVersion >= 3790) {
    return Option.of('winxp64');
  }

  return const Option.none();
}

List<_RegistryValueQuery> _bottleSettingsRegistryQueries({
  required bool includeMacDriverSettings,
}) {
  return <_RegistryValueQuery>[
    const _RegistryValueQuery(key: r'HKCU\Software\Wine', name: 'Version'),
    const _RegistryValueQuery(
      key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
      name: 'CurrentBuild',
    ),
    if (includeMacDriverSettings)
      const _RegistryValueQuery(
        key: r'HKCU\Software\Wine\Mac Driver',
        name: 'RetinaMode',
      ),
    const _RegistryValueQuery(
      key: r'HKCU\Control Panel\Desktop',
      name: 'LogPixels',
    ),
  ];
}

List<String> _registryUpdateArguments(_RegistryValueUpdate update) {
  return <String>[
    'reg',
    'add',
    update.key,
    '-v',
    update.name,
    '-t',
    update.type,
    '-d',
    update.data,
    '-f',
  ];
}

List<String> _registryQueryArguments(_RegistryValueQuery query) {
  return <String>['reg', 'query', query.key, '/v', query.name];
}
