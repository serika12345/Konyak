import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cli/konyak_cli_failure_messages.dart';
import '../cli/konyak_cli_process_runner.dart';
import '../l10n/konyak_localizations.dart';

const macosMenuChannel = MethodChannel('konyak/menu');

class MacosNativeMenuLocalizer extends StatefulWidget {
  const MacosNativeMenuLocalizer({super.key});

  @override
  State<MacosNativeMenuLocalizer> createState() =>
      MacosNativeMenuLocalizerState();
}

class MacosNativeMenuLocalizerState extends State<MacosNativeMenuLocalizer> {
  Map<String, String>? lastPayload;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    synchronizeNativeMenu();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  void synchronizeNativeMenu() {
    final payload = macosNativeMenuLocalizationPayload(
      KonyakLocalizations.of(context),
    );
    if (sameStringMap(lastPayload, payload)) {
      return;
    }

    lastPayload = Map<String, String>.unmodifiable(payload);
    unawaited(sendMacosNativeMenuLocalization(payload));
  }
}

Map<String, String> macosNativeMenuLocalizationPayload(
  KonyakLocalizations localizations,
) {
  return <String, String>{
    'appMenu': 'Konyak',
    'aboutKonyak': localizations.aboutKonyak,
    'settings': localizations.settingsEllipsisMenu,
    'checkForUpdates': localizations.checkForUpdatesMenuItem,
    'reinstallRuntime': localizations.reinstallMacosRuntime,
    'hideKonyak': localizations.hideKonyak,
    'hideOthers': localizations.hideOthers,
    'showAll': localizations.showAll,
    'quitKonyak': localizations.quitKonyak,
    'file': localizations.file,
    'importBottle': localizations.importBottle,
  };
}

Future<void> sendMacosNativeMenuLocalization(
  Map<String, String> payload,
) async {
  try {
    await macosMenuChannel.invokeMethod<void>('setMenuLocalization', payload);
  } on MissingPluginException {
    return;
  }
}

bool sameStringMap(Map<String, String>? left, Map<String, String> right) {
  if (left == null || left.length != right.length) {
    return false;
  }

  for (final entry in right.entries) {
    if (left[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

List<String> validExecutableOpenPathsFromChannel(Object? arguments) {
  if (arguments is! List<Object?>) {
    return const <String>[];
  }

  return validExecutableOpenPaths(arguments.whereType<String>());
}

List<String> validExecutableOpenPaths(Iterable<String> paths) {
  final validPaths = <String>[];
  for (final path in paths) {
    final trimmedPath = path.trim();
    if (isWindowsExecutablePath(trimmedPath)) {
      validPaths.add(trimmedPath);
    }
  }

  return validPaths;
}

bool isWindowsExecutablePath(String path) {
  return path.isNotEmpty && path.toLowerCase().endsWith('.exe');
}

String installGptkFailureMessage(
  ProcessRunResult result, {
  required String command,
}) {
  return commandFailureMessage(command, result);
}

String openUrlFailureMessage(ProcessRunResult result) {
  return commandFailureMessage('open-url', result);
}
