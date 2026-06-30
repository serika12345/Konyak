import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../cli/konyak_cli_failure_messages.dart';
import '../cli/konyak_cli_process_runner.dart';
import '../l10n/konyak_localizations.dart';

part 'home_loader_platform_helpers.freezed.dart';

const macosMenuChannel = MethodChannel('konyak/menu');

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class MacosNativeMenuLocalizationCache
    with _$MacosNativeMenuLocalizationCache {
  const factory MacosNativeMenuLocalizationCache.empty() =
      EmptyMacosNativeMenuLocalizationCache;

  const factory MacosNativeMenuLocalizationCache.synchronized({
    required Map<String, String> payload,
  }) = SynchronizedMacosNativeMenuLocalizationCache;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ExecutableOpenPathsChannelPayload
    with _$ExecutableOpenPathsChannelPayload {
  const factory ExecutableOpenPathsChannelPayload.valid({
    required List<String> paths,
  }) = ValidExecutableOpenPathsChannelPayload;

  const factory ExecutableOpenPathsChannelPayload.partial({
    required List<String> paths,
    required int invalidItemCount,
  }) = PartialExecutableOpenPathsChannelPayload;

  const factory ExecutableOpenPathsChannelPayload.invalid(String reason) =
      InvalidExecutableOpenPathsChannelPayload;
}

class MacosNativeMenuLocalizer extends StatefulWidget {
  const MacosNativeMenuLocalizer({super.key});

  @override
  State<MacosNativeMenuLocalizer> createState() =>
      MacosNativeMenuLocalizerState();
}

class MacosNativeMenuLocalizerState extends State<MacosNativeMenuLocalizer> {
  MacosNativeMenuLocalizationCache localizationCache =
      const MacosNativeMenuLocalizationCache.empty();

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
    if (!macosNativeMenuLocalizationNeedsSync(
      cache: localizationCache,
      payload: payload,
    )) {
      return;
    }

    localizationCache = synchronizedMacosNativeMenuLocalizationCache(payload);
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

MacosNativeMenuLocalizationCache synchronizedMacosNativeMenuLocalizationCache(
  Map<String, String> payload,
) {
  return MacosNativeMenuLocalizationCache.synchronized(
    payload: Map<String, String>.unmodifiable(payload),
  );
}

bool macosNativeMenuLocalizationNeedsSync({
  required MacosNativeMenuLocalizationCache cache,
  required Map<String, String> payload,
}) {
  return switch (cache) {
    EmptyMacosNativeMenuLocalizationCache() => true,
    SynchronizedMacosNativeMenuLocalizationCache(
      payload: final cachedPayload,
    ) =>
      !sameStringMap(cachedPayload, payload),
  };
}

bool sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      right.entries.every((entry) => left[entry.key] == entry.value);
}

ExecutableOpenPathsChannelPayload executableOpenPathsChannelPayloadFrom(
  Object? arguments,
) {
  if (arguments is! List<Object?>) {
    return const ExecutableOpenPathsChannelPayload.invalid(
      'expected a List<String> executable-open payload',
    );
  }

  final stringItems = arguments.whereType<String>().toList(growable: false);
  final invalidItemCount = arguments.length - stringItems.length;
  final paths = validExecutableOpenPaths(stringItems);

  if (invalidItemCount > 0) {
    return ExecutableOpenPathsChannelPayload.partial(
      paths: paths,
      invalidItemCount: invalidItemCount,
    );
  }

  return ExecutableOpenPathsChannelPayload.valid(paths: paths);
}

List<String> validExecutableOpenPaths(Iterable<String> paths) {
  final validPaths = <String>[];
  for (final path in paths) {
    final trimmedPath = path.trim();
    if (isWindowsExecutablePath(trimmedPath)) {
      validPaths.add(trimmedPath);
    }
  }

  return List.unmodifiable(validPaths);
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
