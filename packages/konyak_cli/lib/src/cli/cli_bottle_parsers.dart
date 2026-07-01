import 'dart:convert';

import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';
import 'cli_value_object_parsers.dart';

bool isJsonBottleListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-bottles');
}

BottleId? parseJsonBottleInspectCommand(List<String> arguments) {
  return nullableParsedOption(parseJsonBottleInspectCommandOption(arguments));
}

Option<BottleId> parseJsonBottleInspectCommandOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'inspect-bottle',
        restCount: 1,
      ),
    );

    return $(requiredCliBottleIdOption(results));
  });
}

BottleId? parseJsonBottleProgramsListCommand(List<String> arguments) {
  return nullableParsedOption(
    parseJsonBottleProgramsListCommandOption(arguments),
  );
}

Option<BottleId> parseJsonBottleProgramsListCommandOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'list-bottle-programs',
        restCount: 1,
      ),
    );

    return $(requiredCliBottleIdOption(results));
  });
}

bool isJsonWinetricksVerbListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-winetricks-verbs');
}

BottleCreateRequest? parseJsonBottleCreateRequest(List<String> arguments) {
  return nullableParsedOption(parseJsonBottleCreateRequestOption(arguments));
}

Option<BottleCreateRequest> parseJsonBottleCreateRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'create-bottle',
        options: const <String>['name', 'windows-version'],
        restCount: 0,
      ),
    );
    final name = $(requiredCliOptionOption(results, 'name'));
    final windowsVersion = $(_optionalWindowsVersion(results));

    return BottleCreateRequest(
      name: BottleName(name),
      windowsVersion: windowsVersion,
    );
  });
}

BottleArchiveExportRequest? parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonBottleArchiveExportRequestOption(arguments),
  );
}

Option<BottleArchiveExportRequest> parseJsonBottleArchiveExportRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'export-bottle-archive',
        options: const <String>['archive'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final archivePath = $(requiredCliOptionOption(results, 'archive'));

    return BottleArchiveExportRequest(
      bottleId: bottleId,
      archivePath: BottleArchivePath(archivePath),
    );
  });
}

BottleArchiveImportRequest? parseJsonBottleArchiveImportRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonBottleArchiveImportRequestOption(arguments),
  );
}

Option<BottleArchiveImportRequest> parseJsonBottleArchiveImportRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'import-bottle-archive',
        options: const <String>['archive'],
        restCount: 0,
      ),
    );
    final archivePath = $(requiredCliOptionOption(results, 'archive'));

    return BottleArchiveImportRequest(
      archivePath: BottleArchivePath(archivePath),
    );
  });
}

BottleId? parseJsonBottleDeleteCommand(List<String> arguments) {
  return nullableParsedOption(parseJsonBottleDeleteCommandOption(arguments));
}

Option<BottleId> parseJsonBottleDeleteCommandOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'delete-bottle',
        restCount: 1,
      ),
    );

    return $(requiredCliBottleIdOption(results));
  });
}

BottleRenameRequest? parseJsonBottleRenameRequest(List<String> arguments) {
  return nullableParsedOption(parseJsonBottleRenameRequestOption(arguments));
}

Option<BottleRenameRequest> parseJsonBottleRenameRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'rename-bottle',
        options: const <String>['name'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final name = $(requiredCliOptionOption(results, 'name'));

    return BottleRenameRequest(bottleId: bottleId, name: BottleName(name));
  });
}

BottleMoveRequest? parseJsonBottleMoveRequest(List<String> arguments) {
  return nullableParsedOption(parseJsonBottleMoveRequestOption(arguments));
}

Option<BottleMoveRequest> parseJsonBottleMoveRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'move-bottle',
        options: const <String>['path'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final path = $(requiredCliOptionOption(results, 'path'));

    return BottleMoveRequest(bottleId: bottleId, path: BottlePath(path));
  });
}

WindowsVersionUpdateRequest? parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonWindowsVersionUpdateRequestOption(arguments),
  );
}

Option<WindowsVersionUpdateRequest> parseJsonWindowsVersionUpdateRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'set-windows-version',
        options: const <String>['windows-version'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final windowsVersion = $(
      requiredCliOptionOption(results, 'windows-version'),
    );

    return WindowsVersionUpdateRequest(
      bottleId: bottleId,
      windowsVersion: WindowsVersion(windowsVersion),
    );
  });
}

RuntimeSettingsUpdateRequest? parseJsonRuntimeSettingsUpdateRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonRuntimeSettingsUpdateRequestOption(arguments),
  );
}

Option<RuntimeSettingsUpdateRequest>
parseJsonRuntimeSettingsUpdateRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonBottleCommand(
        arguments,
        command: 'set-runtime-settings',
        options: const <String>['settings-json'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final settingsJson = $(requiredCliOptionOption(results, 'settings-json'));
    final runtimeSettings = $(
      _bottleRuntimeSettingsFromJsonString(settingsJson),
    );

    return RuntimeSettingsUpdateRequest(
      bottleId: bottleId,
      runtimeSettings: runtimeSettings,
    );
  });
}

Option<ArgResults> _parseJsonBottleCommand(
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

Option<WindowsVersion> _optionalWindowsVersion(ArgResults results) {
  return optionalCliOptionOption(results, 'windows-version').match(
    () => results.wasParsed('windows-version')
        ? const Option<WindowsVersion>.none()
        : Option.of(WindowsVersion('win10')),
    (value) => Option.of(WindowsVersion(value)),
  );
}

Option<BottleRuntimeSettings> _bottleRuntimeSettingsFromJsonString(String raw) {
  try {
    return bottleRuntimeSettingsFromJson(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}
