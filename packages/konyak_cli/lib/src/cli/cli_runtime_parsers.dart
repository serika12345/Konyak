import 'package:args/args.dart' hide Option;

import '../io/gptk_wine_installation.dart';
import '../platform/linux/linux_wine_install_requests.dart';
import '../platform/macos/macos_wine_install_requests.dart';
import 'cli_parsers.dart';

bool isJsonRuntimeListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-runtimes');
}

bool isJsonMacosSetupCheckCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'check-macos-setup');
}

GptkWineInstallRequest? parseJsonGptkWineInstallRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'install-gptk-wine',
    options: const <String>['from'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final sourcePath = requiredCliOption(results, 'from');
  if (sourcePath == null) {
    return null;
  }

  return GptkWineInstallRequest(sourcePath: sourcePath);
}

String? parseJsonOpenUrlCommand(List<String> arguments) {
  final results = parseJsonCliCommand(arguments, command: 'open-url');
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final url = requiredCliRest(results);
  if (url != null &&
      (url.startsWith('https://') || url.startsWith('http://'))) {
    return url;
  }

  return null;
}

String? parseJsonRuntimeIdCommand(List<String> arguments, String command) {
  final results = parseJsonCliCommand(arguments, command: command);
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  return requiredCliRest(results);
}

MacosWineInstallRequest? parseJsonMacosWineInstallRequest(
  List<String> arguments,
) {
  final options = parseRuntimeInstallCliOptions(
    arguments,
    command: 'install-macos-wine',
    allowReinstall: true,
  );
  if (options == null) {
    return null;
  }

  return MacosWineInstallRequest.fullInstall(
    sourceManifest: options.sourceManifest,
    force: options.reinstall,
    emitProgress: options.emitProgress,
  );
}

LinuxWineInstallRequest? parseJsonLinuxWineInstallRequest(
  List<String> arguments,
) {
  final options = parseRuntimeInstallCliOptions(
    arguments,
    command: 'install-linux-wine',
    allowReinstall: true,
  );
  if (options == null) {
    return null;
  }

  return LinuxWineInstallRequest.fullInstall(
    sourceManifest: options.sourceManifest,
    force: options.reinstall,
    emitProgress: options.emitProgress,
  );
}

class RuntimeInstallCliOptions {
  RuntimeInstallCliOptions({
    this.sourceManifest,
    this.reinstall = false,
    this.emitProgress = false,
  });

  final String? sourceManifest;
  final bool reinstall;
  final bool emitProgress;
}

RuntimeInstallCliOptions? parseRuntimeInstallCliOptions(
  List<String> arguments, {
  required String command,
  bool allowReinstall = false,
}) {
  if (arguments.length < 2 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final parser = ArgParser(allowTrailingOptions: false)
    ..addOption('source-manifest')
    ..addFlag('reinstall', negatable: false)
    ..addFlag('progress-json', negatable: false)
    ..addFlag('json', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments.sublist(1));
  } on FormatException {
    return null;
  }

  if (results.rest.isNotEmpty || results['json'] != true) {
    return null;
  }

  for (final name in const <String>['source-manifest']) {
    if (hasEmptyParsedCliOption(results, name)) {
      return null;
    }
  }

  final sourceManifest = nonEmptyCliOption(results, 'source-manifest');
  final reinstall = results['reinstall'] == true;
  if (reinstall && !allowReinstall) {
    return null;
  }

  return RuntimeInstallCliOptions(
    sourceManifest: sourceManifest,
    reinstall: reinstall,
    emitProgress: results['progress-json'] == true,
  );
}

String? nonEmptyCliOption(ArgResults results, String name) {
  final value = results[name] as String?;
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}
