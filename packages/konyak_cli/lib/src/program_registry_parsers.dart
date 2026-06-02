part of '../konyak_cli.dart';

BottleRecord _bottleWithRegistryValue({
  required BottleRecord bottle,
  required List<String> arguments,
  required String stdout,
}) {
  final name = _registryValueNameFromArguments(arguments);
  if (name == null) {
    return bottle;
  }

  final data = _registryQueryValue(stdout, name);
  if (data == null) {
    return bottle;
  }

  if (name == 'Version') {
    return _bottleWithWindowsVersion(bottle, data);
  }

  return bottle.copyWith(
    runtimeSettings: _runtimeSettingsWithRegistryValue(
      runtimeSettings: bottle.runtimeSettings,
      arguments: arguments,
      stdout: stdout,
    ),
  );
}

BottleRuntimeSettings _runtimeSettingsWithRegistryValue({
  required BottleRuntimeSettings runtimeSettings,
  required List<String> arguments,
  required String stdout,
}) {
  final name = _registryValueNameFromArguments(arguments);
  if (name == null) {
    return runtimeSettings;
  }

  final data = _registryQueryValue(stdout, name);
  if (data == null) {
    return runtimeSettings;
  }

  return switch (name) {
    'CurrentBuild' => _runtimeSettingsWithBuildVersion(runtimeSettings, data),
    'RetinaMode' => _runtimeSettingsWithRetinaMode(runtimeSettings, data),
    'LogPixels' => _runtimeSettingsWithDpiScaling(runtimeSettings, data),
    _ => runtimeSettings,
  };
}

BottleRecord _bottleWithWindowsVersion(BottleRecord bottle, String data) {
  final windowsVersion = _registryWindowsVersion(data);
  if (windowsVersion == null) {
    return bottle;
  }

  return bottle.copyWith(windowsVersion: windowsVersion);
}

String? _registryWindowsVersion(String data) {
  return switch (data.trim().toLowerCase()) {
    'winxp' => 'winxp64',
    'winxp64' ||
    'win7' ||
    'win8' ||
    'win81' ||
    'win10' ||
    'win11' => data.trim().toLowerCase(),
    _ => null,
  };
}

BottleRuntimeSettings _runtimeSettingsWithBuildVersion(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  final buildVersion = int.tryParse(data.trim());
  if (buildVersion == null || buildVersion < 0 || buildVersion > 999999) {
    return runtimeSettings;
  }

  return runtimeSettings.copyWith(buildVersion: buildVersion);
}

BottleRuntimeSettings _runtimeSettingsWithRetinaMode(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return switch (data.trim().toLowerCase()) {
    'y' => runtimeSettings.copyWith(retinaMode: true),
    'n' => runtimeSettings.copyWith(retinaMode: false),
    _ => runtimeSettings,
  };
}

BottleRuntimeSettings _runtimeSettingsWithDpiScaling(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  final dpiScaling = _registryDwordValue(data);
  if (dpiScaling == null ||
      dpiScaling < 96 ||
      dpiScaling > 480 ||
      (dpiScaling - 96) % 24 != 0) {
    return runtimeSettings;
  }

  return runtimeSettings.copyWith(dpiScaling: dpiScaling);
}

String? _registryValueNameFromArguments(List<String> arguments) {
  final valueIndex = arguments.indexOf('/v');
  if (valueIndex == -1 || valueIndex + 1 >= arguments.length) {
    return null;
  }

  return arguments[valueIndex + 1];
}

String? _registryQueryValue(String output, String name) {
  for (final line in const LineSplitter().convert(output)) {
    final columns = line.trim().split(RegExp(r'\s+'));
    if (columns.length >= 3 && columns.first == name) {
      return columns.sublist(2).join(' ');
    }
  }

  return null;
}

int? _registryDwordValue(String data) {
  final parts = data.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return null;
  }

  final token = parts.first;
  if (token.startsWith('0x') || token.startsWith('0X')) {
    return int.tryParse(token.substring(2), radix: 16);
  }

  return int.tryParse(token);
}
