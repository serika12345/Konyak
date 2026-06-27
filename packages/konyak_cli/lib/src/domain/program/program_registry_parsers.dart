part of '../../../konyak_cli.dart';

BottleRecord _bottleWithRegistryValue({
  required BottleRecord bottle,
  required List<String> arguments,
  required String stdout,
}) {
  return _registryValueNameFromArguments(arguments)
      .flatMap((name) {
        return _registryQueryValue(stdout, name).map((data) {
          return (name: name, data: data);
        });
      })
      .match(
        () => bottle,
        (value) => value.name == 'Version'
            ? _bottleWithWindowsVersion(bottle, value.data)
            : bottle.withRuntimeSettings(
                _runtimeSettingsWithRegistryValue(
                  runtimeSettings: bottle.runtimeSettings,
                  arguments: arguments,
                  stdout: stdout,
                ),
              ),
      );
}

BottleRuntimeSettings _runtimeSettingsWithRegistryValue({
  required BottleRuntimeSettings runtimeSettings,
  required List<String> arguments,
  required String stdout,
}) {
  return _registryValueNameFromArguments(arguments)
      .flatMap((name) {
        return _registryQueryValue(stdout, name).map((data) {
          return (name: name, data: data);
        });
      })
      .match(
        () => runtimeSettings,
        (value) => switch (value.name) {
          'CurrentBuild' => _runtimeSettingsWithBuildVersion(
            runtimeSettings,
            value.data,
          ),
          'RetinaMode' => _runtimeSettingsWithRetinaMode(
            runtimeSettings,
            value.data,
          ),
          'LogPixels' => _runtimeSettingsWithDpiScaling(
            runtimeSettings,
            value.data,
          ),
          _ => runtimeSettings,
        },
      );
}

BottleRecord _bottleWithWindowsVersion(BottleRecord bottle, String data) {
  return _registryWindowsVersion(
    data,
  ).match(() => bottle, bottle.withWindowsVersion);
}

Option<String> _registryWindowsVersion(String data) {
  return switch (data.trim().toLowerCase()) {
    'winxp' => Option.of('winxp64'),
    'winxp64' ||
    'win7' ||
    'win8' ||
    'win81' ||
    'win10' ||
    'win11' => Option.of(data.trim().toLowerCase()),
    _ => const Option.none(),
  };
}

BottleRuntimeSettings _runtimeSettingsWithBuildVersion(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return _nullableOption(int.tryParse(data.trim())).match(
    () => runtimeSettings,
    (buildVersion) => buildVersion < 0 || buildVersion > 999999
        ? runtimeSettings
        : runtimeSettings.withBuildVersion(buildVersion),
  );
}

BottleRuntimeSettings _runtimeSettingsWithRetinaMode(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return switch (data.trim().toLowerCase()) {
    'y' => runtimeSettings.withRetinaMode(true),
    'n' => runtimeSettings.withRetinaMode(false),
    _ => runtimeSettings,
  };
}

BottleRuntimeSettings _runtimeSettingsWithDpiScaling(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return _registryDwordValue(data).match(
    () => runtimeSettings,
    (dpiScaling) =>
        dpiScaling < 96 || dpiScaling > 480 || (dpiScaling - 96) % 24 != 0
        ? runtimeSettings
        : runtimeSettings.withDpiScaling(dpiScaling),
  );
}

Option<String> _registryValueNameFromArguments(List<String> arguments) {
  final valueIndex = arguments.indexOf('/v');
  if (valueIndex == -1 || valueIndex + 1 >= arguments.length) {
    return const Option.none();
  }

  return Option.of(arguments[valueIndex + 1]);
}

Option<String> _registryQueryValue(String output, String name) {
  return const LineSplitter()
      .convert(output)
      .fold<Option<String>>(
        const Option.none(),
        (current, line) => current.match(() {
          final columns = line.trim().split(RegExp(r'\s+'));
          return columns.length >= 3 && columns.first == name
              ? Option.of(columns.sublist(2).join(' '))
              : const Option.none();
        }, (_) => current),
      );
}

Option<int> _registryDwordValue(String data) {
  final parts = data.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return const Option.none();
  }

  final token = parts.first;
  if (token.startsWith('0x') || token.startsWith('0X')) {
    return _nullableOption(int.tryParse(token.substring(2), radix: 16));
  }

  return _nullableOption(int.tryParse(token));
}
