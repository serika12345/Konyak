import 'dart:async';

import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_runner.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../repository/repository_exceptions.dart';
import 'cli_app_process_parsers.dart';
import 'cli_app_process_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';
import 'cli_runtime_parsers.dart';
import 'cli_update_runtime_results.dart';

CliResult runCli(List<String> arguments, {required CliCommandContext context}) {
  try {
    return runCliWithContext(arguments, context);
  } on BottleRepositoryException catch (error) {
    return jsonError(
      exitCode: 74,
      code: 'bottleRepositoryError',
      message: error.message,
    );
  } on AppSettingsRepositoryException catch (error) {
    return jsonError(
      exitCode: 74,
      code: 'appSettingsRepositoryError',
      message: error.message,
    );
  }
}

Future<CliResult> runCliStreaming(
  List<String> arguments, {
  required CliCommandContext context,
  required AsyncProgramRunner asyncProgramRunner,
  required AsyncProgramMetadataExtractor asyncProgramMetadataExtractor,
  required HostProcessSnapshotReader hostProcessSnapshotReader,
  MacosWineStreamingInstaller? macosWineStreamingInstaller,
  LinuxWineStreamingInstaller? linuxWineStreamingInstaller,
}) async {
  final activeMacosWineStreamingInstaller =
      macosWineStreamingInstaller ??
      switch (context.macosWineInstaller) {
        final MacosWineStreamingInstaller installer => installer,
        _ => null,
      };
  final macosWineInstallMatch =
      await parseJsonMacosWineInstallRequestOption(
        arguments,
      ).match<Future<_StreamingInstallMatch>>(
        () async {
          return const _StreamingInstallNotMatched();
        },
        (macosWineInstallRequest) async {
          if (!macosWineInstallRequest.emitProgress ||
              activeMacosWineStreamingInstaller == null) {
            return const _StreamingInstallNotMatched();
          }

          final installResult = await activeMacosWineStreamingInstaller
              .installStreaming(
                macosWineInstallRequest,
                progressSink: context.runtimeInstallProgressSink,
              );
          return _StreamingInstallMatched(
            macosWineInstallCliResult(installResult),
          );
        },
      );
  switch (macosWineInstallMatch) {
    case _StreamingInstallMatched(:final result):
      return result;
    case _StreamingInstallNotMatched():
  }

  final activeLinuxWineStreamingInstaller =
      linuxWineStreamingInstaller ??
      switch (context.linuxWineInstaller) {
        final LinuxWineStreamingInstaller installer => installer,
        _ => null,
      };
  final linuxWineInstallMatch =
      await parseJsonLinuxWineInstallRequestOption(
        arguments,
      ).match<Future<_StreamingInstallMatch>>(
        () async {
          return const _StreamingInstallNotMatched();
        },
        (linuxWineInstallRequest) async {
          if (!linuxWineInstallRequest.emitProgress ||
              activeLinuxWineStreamingInstaller == null) {
            return const _StreamingInstallNotMatched();
          }

          final installResult = await activeLinuxWineStreamingInstaller
              .installStreaming(
                linuxWineInstallRequest,
                progressSink: context.runtimeInstallProgressSink,
              );
          return _StreamingInstallMatched(
            linuxWineInstallCliResult(installResult),
          );
        },
      );
  switch (linuxWineInstallMatch) {
    case _StreamingInstallMatched(:final result):
      return result;
    case _StreamingInstallNotMatched():
  }

  if (isJsonWineProcessListCommand(arguments)) {
    try {
      final activeBottleCatalog =
          context.bottleRepository ?? context.bottleCatalog;
      return await listWineProcessesJsonResultAsync(
        bottleCatalog: activeBottleCatalog,
        programRunPlanner: context.programRunPlanner,
        programRunner: asyncProgramRunner,
        programMetadataExtractor: asyncProgramMetadataExtractor,
        hostProcessSnapshotReader: hostProcessSnapshotReader,
      );
    } on BottleRepositoryException catch (error) {
      return jsonError(
        exitCode: 74,
        code: 'bottleRepositoryError',
        message: error.message,
      );
    } on AppSettingsRepositoryException catch (error) {
      return jsonError(
        exitCode: 74,
        code: 'appSettingsRepositoryError',
        message: error.message,
      );
    }
  }

  return runCli(arguments, context: context);
}

sealed class _StreamingInstallMatch {
  const _StreamingInstallMatch();
}

final class _StreamingInstallNotMatched extends _StreamingInstallMatch {
  const _StreamingInstallNotMatched();
}

final class _StreamingInstallMatched extends _StreamingInstallMatch {
  const _StreamingInstallMatched(this.result);

  final CliResult result;
}
