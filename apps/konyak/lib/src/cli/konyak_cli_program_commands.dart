import 'dart:async';
import 'dart:convert';

import '../bottles/bottle_summary.dart';
import '../files/temporary_install_profile_manifest.dart';
import '../files/temporary_install_profile_manifest_io.dart';
import 'konyak_cli_bottle_payload_parsers.dart';
import 'konyak_cli_bottle_result_types.dart';
import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_program_payload_parsers.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_result_helpers.dart';
import 'program_profile_install_contract.dart';

sealed class ProgramRunSettingsArgument {
  const ProgramRunSettingsArgument();
}

final class NoProgramRunSettings extends ProgramRunSettingsArgument {
  const NoProgramRunSettings();
}

final class UseProgramRunSettings extends ProgramRunSettingsArgument {
  const UseProgramRunSettings(this.settings);

  final ProgramSettingsSummary settings;
}

extension KonyakCliProgramCommands on KonyakCliClient {
  Future<ProgramRunLoadResult> runProgram({
    required String bottleId,
    required String programPath,
    ProgramRunSettingsArgument settings = const NoProgramRunSettings(),
    ProcessStartObserver startObserver = const IgnoreProcessStart(),
  }) {
    final runArguments = <String>[
      'run-program',
      bottleId,
      '--program',
      programPath,
      ...switch (settings) {
        NoProgramRunSettings() => const <String>[],
        UseProgramRunSettings(:final settings) => [
          '--settings-json',
          jsonEncode(settings.toJson()),
        ],
      },
      '--json',
    ];

    return programRunResultFromCommand(
      arguments: runArguments,
      failureMessage: programRunFailureMessage,
      startObserver: startObserver,
    );
  }

  Future<InstallProfileListLoadResult> listInstallProfiles() async {
    final result = await run(['list-install-profiles', '--json']);
    final parsed = parseInstallProfileListPayload(result.stdout);

    return switch (parsed) {
      LoadedInstallProfiles() when result.exitCode == 0 => parsed,
      InstallProfileListLoadFailure(:final message) =>
        InstallProfileListLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      LoadedInstallProfiles() => InstallProfileListLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'list-install-profiles'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<InstallProfileInspectLoadResult> inspectInstallProfile({
    required String profileId,
  }) async {
    final result = await run(['inspect-install-profile', profileId, '--json']);
    final parsed = parseInstallProfileInspectPayload(result.stdout);

    return switch (parsed) {
      InspectedInstallProfile() when result.exitCode == 0 => parsed,
      InstallProfileInspectLoadFailure(:final message) =>
        InstallProfileInspectLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      InspectedInstallProfile() => InstallProfileInspectLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'inspect-install-profile'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<InstallProfileMutationLoadResult> validateInstallProfile({
    required String sourcePath,
  }) {
    return _installProfileMutationResultFromCommand(
      arguments: ['validate-install-profile', '--from', sourcePath, '--json'],
      command: 'validate-install-profile',
      expectedOperation: 'validate',
    );
  }

  Future<InstallProfileMutationLoadResult> validateInstallProfileManifest({
    required String manifestJson,
  }) {
    return _withTemporaryInstallProfileManifest(
      manifestJson: manifestJson,
      execute: (sourcePath) => validateInstallProfile(sourcePath: sourcePath),
    );
  }

  Future<InstallProfileMutationLoadResult> importInstallProfile({
    required String sourcePath,
  }) {
    return _installProfileMutationResultFromCommand(
      arguments: ['import-install-profile', '--from', sourcePath, '--json'],
      command: 'import-install-profile',
      expectedOperation: 'import',
    );
  }

  Future<InstallProfileMutationLoadResult> importInstallProfileManifest({
    required String manifestJson,
  }) {
    return _withTemporaryInstallProfileManifest(
      manifestJson: manifestJson,
      execute: (sourcePath) => importInstallProfile(sourcePath: sourcePath),
    );
  }

  Future<InstallProfileMutationLoadResult> updateInstallProfile({
    required String profileId,
    required String expectedDigest,
    required String sourcePath,
  }) {
    return _installProfileMutationResultFromCommand(
      arguments: [
        'update-install-profile',
        profileId,
        '--from',
        sourcePath,
        '--expected-digest',
        expectedDigest,
        '--json',
      ],
      command: 'update-install-profile',
      expectedOperation: 'update',
    );
  }

  Future<InstallProfileMutationLoadResult> updateInstallProfileManifest({
    required String profileId,
    required String expectedDigest,
    required String manifestJson,
  }) {
    return _withTemporaryInstallProfileManifest(
      manifestJson: manifestJson,
      execute: (sourcePath) => updateInstallProfile(
        profileId: profileId,
        expectedDigest: expectedDigest,
        sourcePath: sourcePath,
      ),
    );
  }

  Future<InstallProfileMutationLoadResult> exportInstallProfile({
    required String profileId,
    required String destinationPath,
  }) {
    return _installProfileMutationResultFromCommand(
      arguments: [
        'export-install-profile',
        profileId,
        '--to',
        destinationPath,
        '--json',
      ],
      command: 'export-install-profile',
      expectedOperation: 'export',
    );
  }

  Future<InstallProfileMutationLoadResult> deleteInstallProfile({
    required String profileId,
    required String expectedDigest,
  }) {
    return _installProfileMutationResultFromCommand(
      arguments: [
        'delete-install-profile',
        profileId,
        '--expected-digest',
        expectedDigest,
        '--json',
      ],
      command: 'delete-install-profile',
      expectedOperation: 'delete',
    );
  }

  Future<InstallProfileMutationLoadResult>
  _installProfileMutationResultFromCommand({
    required List<String> arguments,
    required String command,
    required String expectedOperation,
  }) async {
    final result = await run(arguments);
    final parsed = parseInstallProfileMutationPayload(result.stdout);

    return switch (parsed) {
      InstallProfileMutationLoadFailure(:final message) =>
        InstallProfileMutationLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      _
          when result.exitCode == 0 &&
              _matchesInstallProfileMutationOperation(
                parsed,
                expectedOperation,
              ) =>
        parsed,
      _ => InstallProfileMutationLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, command),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<InstallProfileMutationLoadResult>
  _withTemporaryInstallProfileManifest({
    required String manifestJson,
    required Future<InstallProfileMutationLoadResult> Function(
      String sourcePath,
    )
    execute,
  }) async {
    final result = await const DartIoTemporaryInstallProfileManifestExecutor()
        .execute(manifestJson: manifestJson, action: execute);
    return switch (result) {
      ExecutedTemporaryInstallProfileManifest(:final value) => value,
      TemporaryInstallProfileManifestFailure(
        :final message,
        :final diagnostic,
      ) =>
        InstallProfileMutationLoadFailure(
          exitCode: -1,
          message: message,
          diagnostic: diagnostic,
        ),
    };
  }

  Future<ProgramProfileApplyLoadResult> applyProgramProfile({
    required String profileId,
    required String bottleId,
    required String programPath,
  }) async {
    final result = await run([
      'apply-program-profile',
      profileId,
      '--bottle',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);
    final parsed = parseProgramProfileApplyPayload(result.stdout);

    return switch (parsed) {
      AppliedProgramProfile() when result.exitCode == 0 => parsed,
      ProgramProfileApplyLoadFailure(:final message) =>
        ProgramProfileApplyLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      AppliedProgramProfile() => ProgramProfileApplyLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'apply-program-profile'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramProfileInstallLoadResult> installProgramProfile({
    required String profileId,
    required String bottleId,
    ProgramProfileInstallProgressObservation progressObservation =
        const IgnoreProgramProfileInstallProgress(),
  }) async {
    final arguments = <String>[
      'install-program-profile',
      profileId,
      '--bottle',
      bottleId,
    ];
    final result = await switch (progressObservation) {
      IgnoreProgramProfileInstallProgress() => run(<String>[
        ...arguments,
        '--json',
      ]),
      NotifyProgramProfileInstallProgress(:final onProgress) =>
        processRunner.run(
          executable,
          <String>[...baseArguments, ...arguments, '--progress-json', '--json'],
          workingDirectory: workingDirectory,
          environment: <String, String>{
            ...environment,
            ...launcherEnvironment(),
          },
          observation: ObservedProcessRun(
            startObserver: const IgnoreProcessStart(),
            stdoutObserver: NotifyProcessStdoutLine((line) {
              switch (parseProgramProfileInstallProgressPayload(line)) {
                case ParsedProgramProfileInstallProgress(:final progress):
                  onProgress(progress);
                case InvalidProgramProfileInstallProgress():
                  break;
              }
            }),
          ),
        ),
    };
    final parsed = parseProgramProfileInstallCommandPayload(result.stdout);

    return switch (parsed) {
      ParsedProgramProfileInstall(:final profile) when result.exitCode == 0 =>
        InstalledProgramProfile(profile),
      ProgramProfileInstallCommandFailure(:final message) =>
        ProgramProfileInstallLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      ParsedProgramProfileInstall() ||
      ProgramProfileInstallParseFailure() => ProgramProfileInstallLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'install-program-profile'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> pinProgram({
    required String bottleId,
    required String name,
    required String programPath,
  }) async {
    final result = await run([
      'pin-program',
      bottleId,
      '--name',
      name,
      '--program',
      programPath,
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'pin-program',
    );
  }

  Future<BottleUpdateLoadResult> unpinProgram({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await run([
      'unpin-program',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'unpin-program',
    );
  }

  Future<BottleUpdateLoadResult> renamePinnedProgram({
    required String bottleId,
    required String programPath,
    required String name,
  }) async {
    final result = await run([
      'rename-pinned-program',
      bottleId,
      '--program',
      programPath,
      '--name',
      name,
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-pinned-program',
    );
  }

  Future<ProgramSettingsLoadResult> getProgramSettings({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await run([
      'get-program-settings',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return programSettingsResultFromCommand(
      result: result,
      command: 'get-program-settings',
    );
  }

  Future<ProgramSettingsLoadResult> setProgramSettings({
    required String bottleId,
    required String programPath,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await run([
      'set-program-settings',
      bottleId,
      '--program',
      programPath,
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);

    return programSettingsResultFromCommand(
      result: result,
      command: 'set-program-settings',
    );
  }

  Future<ProgramRunLoadResult> runBottleCommand({
    required String bottleId,
    required String command,
    ProcessStartObserver startObserver = const IgnoreProcessStart(),
  }) {
    return programRunResultFromCommand(
      arguments: [
        'run-bottle-command',
        bottleId,
        '--command',
        command,
        '--json',
      ],
      failureMessage: (result) =>
          commandFailureMessage('run-bottle-command', result),
      startObserver: startObserver,
    );
  }

  Future<ProgramRunLoadResult> runWinetricksVerb({
    required String bottleId,
    required String verb,
  }) {
    return programRunResultFromCommand(
      arguments: ['run-winetricks', bottleId, '--verb', verb, '--json'],
      failureMessage: (result) =>
          operationFailureMessage(result, 'run-winetricks'),
    );
  }

  Future<GraphicsBackendHintsLoadResult> suggestGraphicsBackend({
    required String programPath,
  }) async {
    final result = await run([
      'suggest-graphics-backend',
      '--program',
      programPath,
      '--json',
    ]);

    final parsed = parseGraphicsBackendHintsPayload(result.stdout);

    return switch (parsed) {
      LoadedGraphicsBackendHints() when result.exitCode == 0 => parsed,
      GraphicsBackendHintsLoadFailure(:final message) =>
        GraphicsBackendHintsLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      LoadedGraphicsBackendHints() => GraphicsBackendHintsLoadFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('suggest-graphics-backend', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleLocationOpenResult> openBottleLocation({
    required String bottleId,
    required String location,
  }) async {
    final result = await run([
      'open-bottle-location',
      bottleId,
      '--location',
      location,
      '--json',
    ]);

    final parsed = parseBottleLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedBottleLocation() when result.exitCode == 0 => parsed,
      BottleLocationOpenFailure(:final message) => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedBottleLocation() => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('open-bottle-location', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramLocationOpenResult> openProgramLocation({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await run([
      'open-program-location',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    final parsed = parseProgramLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedProgramLocation() when result.exitCode == 0 => parsed,
      ProgramLocationOpenFailure(:final message) => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedProgramLocation() => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('open-program-location', result),
        diagnostic: result.stderr,
      ),
    };
  }
}

bool _matchesInstallProfileMutationOperation(
  InstallProfileMutationLoadResult result,
  String operation,
) {
  return switch ((result, operation)) {
    (ValidatedInstallProfile(), 'validate') ||
    (ImportedInstallProfile(), 'import') ||
    (UpdatedInstallProfile(), 'update') ||
    (ExportedInstallProfile(), 'export') ||
    (DeletedInstallProfile(), 'delete') => true,
    _ => false,
  };
}
