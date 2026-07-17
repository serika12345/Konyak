import 'dart:convert';

import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';

ProgramPinRequest? parseJsonProgramPinRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramPinRequestOption(arguments));
}

Option<ProgramPinRequest> parseJsonProgramPinRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'pin-program',
        options: const <String>['name', 'program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final name = $(_requiredProgramName(results, 'name'));

    return ProgramPinRequest(
      bottleId: target.bottleId,
      name: name,
      programPath: target.programPath,
    );
  });
}

ProgramUnpinRequest? parseJsonProgramUnpinRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramUnpinRequestOption(arguments));
}

Option<ProgramUnpinRequest> parseJsonProgramUnpinRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'unpin-program',
        options: const <String>['program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));

    return ProgramUnpinRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
    );
  });
}

ProgramRenameRequest? parseJsonProgramRenameRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramRenameRequestOption(arguments));
}

Option<ProgramRenameRequest> parseJsonProgramRenameRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'rename-pinned-program',
        options: const <String>['program', 'name'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final name = $(_requiredProgramName(results, 'name'));

    return ProgramRenameRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
      name: name,
    );
  });
}

ProgramSettingsRequest? parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramSettingsRequestOption(arguments),
  );
}

Option<ProgramSettingsRequest> parseJsonProgramSettingsRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'get-program-settings',
        options: const <String>['program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));

    return ProgramSettingsRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
    );
  });
}

ProgramSettingsUpdateRequest? parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramSettingsUpdateRequestOption(arguments),
  );
}

bool isProgramSettingsUpdateJsonCommand(List<String> arguments) {
  return arguments.isNotEmpty &&
      arguments.first == 'set-program-settings' &&
      arguments.contains('--settings-json') &&
      arguments.contains('--json');
}

Option<ProgramSettingsUpdateRequest>
parseJsonProgramSettingsUpdateRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'set-program-settings',
        options: const <String>['program', 'settings-json'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final settingsJson = $(_requiredCliOption(results, 'settings-json'));
    final settings = $(_programSettingsRecordFromJsonString(settingsJson));

    return ProgramSettingsUpdateRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
      settings: settings,
    );
  });
}

class InstallProfileListCliRequest {
  const InstallProfileListCliRequest();
}

InstallProfileListCliRequest? parseJsonInstallProfileListCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonInstallProfileListCliRequestOption(arguments),
  );
}

Option<InstallProfileListCliRequest>
parseJsonInstallProfileListCliRequestOption(List<String> arguments) {
  return _parseJsonProgramMutationCommand(
    arguments,
    command: 'list-install-profiles',
    options: const <String>[],
    restCount: 0,
  ).map((_) => const InstallProfileListCliRequest());
}

class InstallProfileInspectCliRequest {
  const InstallProfileInspectCliRequest({required this.profileId});

  final ProfileId profileId;
}

InstallProfileInspectCliRequest? parseJsonInstallProfileInspectCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonInstallProfileInspectCliRequestOption(arguments),
  );
}

Option<InstallProfileInspectCliRequest>
parseJsonInstallProfileInspectCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'inspect-install-profile',
        options: const <String>[],
        restCount: 1,
      ),
    );
    final profileId = $(_requiredProfileIdFromRest(results));

    return InstallProfileInspectCliRequest(profileId: profileId);
  });
}

class InstallProfileValidateCliRequest {
  const InstallProfileValidateCliRequest({required this.sourcePath});

  final String sourcePath;
}

InstallProfileValidateCliRequest? parseJsonInstallProfileValidateCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    Option.Do(($) {
      final results = $(
        _parseJsonProgramMutationCommand(
          arguments,
          command: 'validate-install-profile',
          options: const <String>['from'],
          restCount: 0,
        ),
      );
      return InstallProfileValidateCliRequest(
        sourcePath: $(_requiredCliOption(results, 'from')),
      );
    }),
  );
}

class InstallProfileImportCliRequest {
  const InstallProfileImportCliRequest({required this.sourcePath});

  final String sourcePath;
}

InstallProfileImportCliRequest? parseJsonInstallProfileImportCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    Option.Do(($) {
      final results = $(
        _parseJsonProgramMutationCommand(
          arguments,
          command: 'import-install-profile',
          options: const <String>['from'],
          restCount: 0,
        ),
      );
      return InstallProfileImportCliRequest(
        sourcePath: $(_requiredCliOption(results, 'from')),
      );
    }),
  );
}

class InstallProfileUpdateCliRequest {
  const InstallProfileUpdateCliRequest({
    required this.profileId,
    required this.sourcePath,
    required this.expectedDigest,
  });

  final ProfileId profileId;
  final String sourcePath;
  final ProfileManifestDigest expectedDigest;
}

InstallProfileUpdateCliRequest? parseJsonInstallProfileUpdateCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    Option.Do(($) {
      final results = $(
        _parseJsonProgramMutationCommand(
          arguments,
          command: 'update-install-profile',
          options: const <String>['from', 'expected-digest'],
          restCount: 1,
        ),
      );
      return InstallProfileUpdateCliRequest(
        profileId: $(_requiredProfileIdFromRest(results)),
        sourcePath: $(_requiredCliOption(results, 'from')),
        expectedDigest: $(
          _requiredCliOption(
            results,
            'expected-digest',
          ).flatMap(_profileManifestDigest),
        ),
      );
    }),
  );
}

class InstallProfileExportCliRequest {
  const InstallProfileExportCliRequest({
    required this.profileId,
    required this.destinationPath,
  });

  final ProfileId profileId;
  final String destinationPath;
}

InstallProfileExportCliRequest? parseJsonInstallProfileExportCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    Option.Do(($) {
      final results = $(
        _parseJsonProgramMutationCommand(
          arguments,
          command: 'export-install-profile',
          options: const <String>['to'],
          restCount: 1,
        ),
      );
      return InstallProfileExportCliRequest(
        profileId: $(_requiredProfileIdFromRest(results)),
        destinationPath: $(_requiredCliOption(results, 'to')),
      );
    }),
  );
}

class InstallProfileDeleteCliRequest {
  const InstallProfileDeleteCliRequest({
    required this.profileId,
    required this.expectedDigest,
  });

  final ProfileId profileId;
  final ProfileManifestDigest expectedDigest;
}

InstallProfileDeleteCliRequest? parseJsonInstallProfileDeleteCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    Option.Do(($) {
      final results = $(
        _parseJsonProgramMutationCommand(
          arguments,
          command: 'delete-install-profile',
          options: const <String>['expected-digest'],
          restCount: 1,
        ),
      );
      return InstallProfileDeleteCliRequest(
        profileId: $(_requiredProfileIdFromRest(results)),
        expectedDigest: $(
          _requiredCliOption(
            results,
            'expected-digest',
          ).flatMap(_profileManifestDigest),
        ),
      );
    }),
  );
}

class ProgramProfileApplyCliRequest {
  const ProgramProfileApplyCliRequest({
    required this.profileId,
    required this.bottleId,
    required this.programPath,
  });

  final ProfileId profileId;
  final BottleId bottleId;
  final ProgramPath programPath;
}

class ProgramProfileInstallCliRequest {
  const ProgramProfileInstallCliRequest({
    required this.profileId,
    required this.bottleId,
    required this.emitProgress,
  });

  final ProfileId profileId;
  final BottleId bottleId;
  final bool emitProgress;
}

ProgramProfileInstallCliRequest? parseJsonProgramProfileInstallRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramProfileInstallRequestOption(arguments),
  );
}

Option<ProgramProfileInstallCliRequest>
parseJsonProgramProfileInstallRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'install-program-profile',
        options: const <String>['bottle'],
        flags: const <String>['progress-json'],
        restCount: 1,
      ),
    );
    final profileId = $(_requiredProfileIdFromRest(results));
    final bottleId = $(_requiredBottleIdOption(results, 'bottle'));

    return ProgramProfileInstallCliRequest(
      profileId: profileId,
      bottleId: bottleId,
      emitProgress: results['progress-json'] == true,
    );
  });
}

ProgramProfileApplyCliRequest? parseJsonProgramProfileApplyRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramProfileApplyRequestOption(arguments),
  );
}

Option<ProgramProfileApplyCliRequest> parseJsonProgramProfileApplyRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'apply-program-profile',
        options: const <String>['bottle', 'program'],
        restCount: 1,
      ),
    );
    final profileId = $(_requiredProfileIdFromRest(results));
    final bottleId = $(_requiredBottleIdOption(results, 'bottle'));
    final programPath = $(_requiredProgramPath(results, 'program'));

    return ProgramProfileApplyCliRequest(
      profileId: profileId,
      bottleId: bottleId,
      programPath: programPath,
    );
  });
}

class ProgramProfileRepairCliRequest {
  const ProgramProfileRepairCliRequest({
    required this.profileId,
    required this.bottleId,
  });

  final ProfileId profileId;
  final BottleId bottleId;
}

ProgramProfileRepairCliRequest? parseJsonProgramProfileRepairRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramProfileRepairRequestOption(arguments),
  );
}

Option<ProgramProfileRepairCliRequest>
parseJsonProgramProfileRepairRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'repair-profile',
        options: const <String>['bottle'],
        restCount: 1,
      ),
    );
    final profileId = $(_requiredProfileIdFromRest(results));
    final bottleId = $(_requiredBottleIdOption(results, 'bottle'));

    return ProgramProfileRepairCliRequest(
      profileId: profileId,
      bottleId: bottleId,
    );
  });
}

class PinnedProgramLaunchCliRequest {
  const PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

PinnedProgramLaunchCliRequest? parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonPinnedProgramLaunchCliRequestOption(arguments),
  );
}

Option<PinnedProgramLaunchCliRequest>
parseJsonPinnedProgramLaunchCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'launch-pinned-program',
        options: const <String>['manifest'],
        restCount: 0,
      ),
    );
    final manifestPath = $(_requiredCliOption(results, 'manifest'));

    return PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
  });
}

Option<ArgResults> _parseJsonProgramMutationCommand(
  List<String> arguments, {
  required String command,
  required Iterable<String> options,
  required int restCount,
  Iterable<String> flags = const <String>[],
}) {
  return Option.Do(($) {
    final results = $(
      Option.fromNullable(
        parseJsonCliCommand(
          arguments,
          command: command,
          options: options,
          flags: flags,
        ),
      ),
    );

    if (!hasRestCount(results, restCount)) {
      return $(const Option<ArgResults>.none());
    }

    return results;
  });
}

Option<({BottleId bottleId, ProgramPath programPath})>
_programMutationTargetFromResults(ArgResults results) {
  return Option.Do(($) {
    final bottleId = $(_requiredBottleId(results));
    final programPath = $(_requiredProgramPath(results, 'program'));

    return (bottleId: bottleId, programPath: programPath);
  });
}

Option<BottleId> _requiredBottleId(ArgResults results) {
  return Option.fromNullable(requiredCliRest(results)).map(BottleId.new);
}

Option<BottleId> _requiredBottleIdOption(ArgResults results, String name) {
  return _requiredCliOption(results, name).map(BottleId.new);
}

Option<ProfileId> _requiredProfileIdFromRest(ArgResults results) {
  return Option.fromNullable(requiredCliRest(results)).map(ProfileId.new);
}

Option<ProgramPath> _requiredProgramPath(ArgResults results, String name) {
  return _requiredCliOption(results, name).map(ProgramPath.new);
}

Option<ProgramName> _requiredProgramName(ArgResults results, String name) {
  return _requiredCliOption(results, name).map(ProgramName.new);
}

Option<String> _requiredCliOption(ArgResults results, String name) {
  return Option.fromNullable(requiredCliOption(results, name));
}

Option<ProfileManifestDigest> _profileManifestDigest(String value) {
  try {
    return Option.of(ProfileManifestDigest(value));
  } on ArgumentError catch (_) {
    return const Option.none();
  }
}

Option<ProgramSettingsRecord> _programSettingsRecordFromJsonString(String raw) {
  try {
    return programSettingsRecordFromJson(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}

T? _nullableParsedRequest<T>(Option<T> request) {
  return request.match(() => null, (value) => value);
}
