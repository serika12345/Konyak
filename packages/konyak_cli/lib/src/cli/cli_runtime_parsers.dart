import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/shared/domain_value_objects.dart';
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

Option<GptkWineInstallRequest> parseJsonGptkWineInstallRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonRuntimeCommand(
        arguments,
        command: 'install-gptk-wine',
        options: const <String>['from'],
        restCount: 0,
      ),
    );
    final sourcePath = $(requiredCliOptionOption(results, 'from'));

    return GptkWineInstallRequest(sourcePath: sourcePath);
  });
}

Option<String> parseJsonOpenUrlCommandOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonRuntimeCommand(arguments, command: 'open-url', restCount: 1),
    );
    final url = $(requiredCliRestOption(results));

    return $(_httpUrl(url));
  });
}

Option<String> parseJsonRuntimeIdCommandOption(
  List<String> arguments,
  String command,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonRuntimeCommand(arguments, command: command, restCount: 1),
    );

    return $(requiredCliRestOption(results));
  });
}

Option<MacosWineInstallRequest> parseJsonMacosWineInstallRequestOption(
  List<String> arguments,
) {
  return parseRuntimeInstallCliOptionsOption(
    arguments,
    command: 'install-macos-wine',
    allowReinstall: true,
  ).map(
    (options) => MacosWineInstallRequest.fullInstall(
      sourceManifest: options.sourceManifest.map(RuntimeSourceManifestUrl.new),
      force: options.reinstall,
      emitProgress: options.emitProgress,
    ),
  );
}

Option<LinuxWineInstallRequest> parseJsonLinuxWineInstallRequestOption(
  List<String> arguments,
) {
  return parseRuntimeInstallCliOptionsOption(
    arguments,
    command: 'install-linux-wine',
    allowReinstall: true,
  ).map(
    (options) => LinuxWineInstallRequest.fullInstall(
      sourceManifest: options.sourceManifest.map(RuntimeSourceManifestUrl.new),
      force: options.reinstall,
      emitProgress: options.emitProgress,
    ),
  );
}

class RuntimeInstallCliOptions {
  RuntimeInstallCliOptions({
    this.sourceManifest = const Option.none(),
    this.reinstall = false,
    this.emitProgress = false,
  });

  final Option<String> sourceManifest;
  final bool reinstall;
  final bool emitProgress;
}

Option<RuntimeInstallCliOptions> parseRuntimeInstallCliOptionsOption(
  List<String> arguments, {
  required String command,
  bool allowReinstall = false,
}) {
  if (arguments.length < 2 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return const Option.none();
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
    return const Option.none();
  }

  if (results.rest.isNotEmpty || results['json'] != true) {
    return const Option.none();
  }

  if (hasEmptyParsedCliOption(results, 'source-manifest')) {
    return const Option.none();
  }

  final reinstall = results['reinstall'] == true;
  if (reinstall && !allowReinstall) {
    return const Option.none();
  }

  return Option.of(
    RuntimeInstallCliOptions(
      sourceManifest: nonEmptyCliOptionOption(results, 'source-manifest'),
      reinstall: reinstall,
      emitProgress: results['progress-json'] == true,
    ),
  );
}

Option<String> nonEmptyCliOptionOption(ArgResults results, String name) {
  final value = results[name] as String?;
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return const Option.none();
  }

  return Option.of(normalized);
}

Option<ArgResults> _parseJsonRuntimeCommand(
  List<String> arguments, {
  required String command,
  Iterable<String> options = const <String>[],
  required int restCount,
}) {
  return Option.Do(($) {
    final results = $(
      parseJsonCliCommandOption(arguments, command: command, options: options),
    );

    if (!hasRestCount(results, restCount)) {
      return $(const Option<ArgResults>.none());
    }

    return results;
  });
}

Option<String> _httpUrl(String url) {
  if (url.startsWith('https://') || url.startsWith('http://')) {
    return Option.of(url);
  }

  return const Option.none();
}
