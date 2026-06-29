import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/platform_location_paths.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_parsers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_location_parsers.dart';
import 'cli_program_catalog_json.dart';
import 'cli_result_model.dart';

CliResult? handleLocationCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final bottleLocationOpenCliRequest = parseJsonBottleLocationOpenCliRequest(
    arguments,
  );
  if (bottleLocationOpenCliRequest != null) {
    return openBottleLocationJsonResult(bottleLocationOpenCliRequest, context);
  }

  final programLocationOpenCliRequest = parseJsonProgramLocationOpenCliRequest(
    arguments,
  );
  if (programLocationOpenCliRequest != null) {
    return openProgramLocationJsonResult(
      programLocationOpenCliRequest,
      context,
    );
  }

  return null;
}

CliResult openBottleLocationJsonResult(
  BottleLocationOpenCliRequest request,
  CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return pathOpenerUnavailableError();
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final path = bottleLocationPath(
        bottle: bottle,
        location: request.location,
      );
      return path.match(
        () => jsonError(
          exitCode: 65,
          code: 'unsupportedBottleLocation',
          message: 'Bottle location is not supported.',
          extra: <String, Object?>{'location': request.location},
        ),
        (path) => switch (opener.openPath(PathOpenTarget(path))) {
          PathOpenCompleted() => jsonSuccess(<String, Object?>{
            'openedLocation': <String, Object?>{
              'bottleId': request.bottleId.value,
              'location': request.location,
              'path': path,
            },
          }),
          PathOpenFailed(:final message) => jsonError(
            exitCode: 75,
            code: 'bottleLocationOpenFailed',
            message: message,
            extra: <String, Object?>{
              'bottleId': request.bottleId.value,
              'location': request.location,
              'path': path,
            },
          ),
        },
      );
    },
  );
}

CliResult openProgramLocationJsonResult(
  ProgramLocationOpenCliRequest request,
  CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return pathOpenerUnavailableError();
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      if (!hasPinnedProgram(bottle, request.programPath)) {
        return jsonError(
          exitCode: 66,
          code: 'programNotPinned',
          message: 'Program is not pinned.',
          extra: <String, Object?>{'programPath': request.programPath},
        );
      }

      final path = request.programPath;
      return switch (opener.revealPath(PathRevealTarget(path))) {
        PathOpenCompleted() => jsonSuccess(<String, Object?>{
          'openedProgramLocation': <String, Object?>{
            'bottleId': request.bottleId.value,
            'programPath': request.programPath,
            'path': path,
          },
        }),
        PathOpenFailed(:final message) => jsonError(
          exitCode: 75,
          code: 'programLocationOpenFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': request.bottleId.value,
            'programPath': request.programPath,
            'path': path,
          },
        ),
      };
    },
  );
}

CliResult pathOpenerUnavailableError() {
  return unavailableJsonError(
    code: 'pathOpenerUnavailable',
    subject: 'Path opener',
  );
}

CliResult? handleWinetricksVerbCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  if (!isJsonWinetricksVerbListCommand(arguments)) {
    return null;
  }

  return winetricksVerbListJsonResult(
    context.winetricksVerbRepository.listVerbs(),
  );
}

CliResult winetricksVerbListJsonResult(WinetricksVerbListResult result) {
  return switch (result) {
    WinetricksVerbListCompleted(:final categories) => jsonSuccess(
      <String, Object?>{
        'winetricks': <String, Object?>{
          'categories': categories
              .map(winetricksCategoryRecordJson)
              .toList(growable: false),
        },
      },
    ),
    WinetricksVerbListFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'winetricksVerbsUnavailable',
      message: message,
    ),
  };
}
