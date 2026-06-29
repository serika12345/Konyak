import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import 'external_payload_helpers.dart';

BottleRecord bottleWithRegistryValue({
  required BottleRecord bottle,
  required List<String> arguments,
  required String stdout,
}) {
  return registryValueNameFromArguments(arguments)
      .flatMap((name) {
        return registryQueryValue(stdout, name).map((data) {
          return (name: name, data: data);
        });
      })
      .match(
        () => bottle,
        (value) => value.name == 'Version'
            ? bottleWithWindowsVersion(bottle, value.data)
            : bottle.withRuntimeSettings(
                runtimeSettingsWithRegistryValue(
                  runtimeSettings: bottle.runtimeSettings,
                  arguments: arguments,
                  stdout: stdout,
                ),
              ),
      );
}

BottleRuntimeSettings runtimeSettingsWithRegistryValue({
  required BottleRuntimeSettings runtimeSettings,
  required List<String> arguments,
  required String stdout,
}) {
  return registryValueNameFromArguments(arguments)
      .flatMap((name) {
        return registryQueryValue(stdout, name).map((data) {
          return (name: name, data: data);
        });
      })
      .match(
        () => runtimeSettings,
        (value) => switch (value.name) {
          'CurrentBuild' => runtimeSettingsWithBuildVersion(
            runtimeSettings,
            value.data,
          ),
          'RetinaMode' => runtimeSettingsWithRetinaMode(
            runtimeSettings,
            value.data,
          ),
          'LogPixels' => runtimeSettingsWithDpiScaling(
            runtimeSettings,
            value.data,
          ),
          _ => runtimeSettings,
        },
      );
}

BottleRecord bottleWithWindowsVersion(BottleRecord bottle, String data) {
  return registryWindowsVersion(data).match(
    () => bottle,
    (value) => bottle.withWindowsVersion(WindowsVersion(value)),
  );
}

Option<String> registryWindowsVersion(String data) {
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

BottleRuntimeSettings runtimeSettingsWithBuildVersion(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return nullableOption(int.tryParse(data.trim())).match(
    () => runtimeSettings,
    (buildVersion) => buildVersion < 0 || buildVersion > 999999
        ? runtimeSettings
        : runtimeSettings.withBuildVersion(buildVersion),
  );
}

BottleRuntimeSettings runtimeSettingsWithRetinaMode(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return switch (data.trim().toLowerCase()) {
    'y' => runtimeSettings.withRetinaMode(true),
    'n' => runtimeSettings.withRetinaMode(false),
    _ => runtimeSettings,
  };
}

BottleRuntimeSettings runtimeSettingsWithDpiScaling(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return registryDwordValue(data).match(
    () => runtimeSettings,
    (dpiScaling) =>
        dpiScaling < 96 || dpiScaling > 480 || (dpiScaling - 96) % 24 != 0
        ? runtimeSettings
        : runtimeSettings.withDpiScaling(dpiScaling),
  );
}

Option<String> registryValueNameFromArguments(List<String> arguments) {
  final valueIndex = arguments.indexOf('/v');
  if (valueIndex == -1 || valueIndex + 1 >= arguments.length) {
    return const Option.none();
  }

  return Option.of(arguments[valueIndex + 1]);
}

Option<String> registryQueryValue(String output, String name) {
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

Option<int> registryDwordValue(String data) {
  final parts = data.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return const Option.none();
  }

  final token = parts.first;
  if (token.startsWith('0x') || token.startsWith('0X')) {
    return nullableOption(int.tryParse(token.substring(2), radix: 16));
  }

  return nullableOption(int.tryParse(token));
}
