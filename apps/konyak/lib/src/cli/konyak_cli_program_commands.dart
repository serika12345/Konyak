import 'dart:async';
import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'konyak_cli_bottle_payload_parsers.dart';
import 'konyak_cli_bottle_result_types.dart';
import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_program_payload_parsers.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_result_helpers.dart';

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

  Future<InstallProgramProfileLoadResult> installProfile({
    required String profileId,
    required String bottleId,
    required String installerPath,
  }) async {
    final result = await run([
      'install-profile',
      profileId,
      '--bottle',
      bottleId,
      '--installer',
      installerPath,
      '--json',
    ]);

    final parsed = parseInstallProgramProfilePayload(result.stdout);

    return switch (parsed) {
      InstalledProgramProfile() when result.exitCode == 0 => parsed,
      InstallProgramProfileLoadFailure(:final message) =>
        InstallProgramProfileLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      InstalledProgramProfile() => InstallProgramProfileLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'install-profile'),
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
