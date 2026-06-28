part of '../../konyak_cli.dart';

CliResult? _handleLocationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final bottleLocationOpenCliRequest = _parseJsonBottleLocationOpenCliRequest(
    arguments,
  );
  if (bottleLocationOpenCliRequest != null) {
    return _openBottleLocationJsonResult(bottleLocationOpenCliRequest, context);
  }

  final programLocationOpenCliRequest = _parseJsonProgramLocationOpenCliRequest(
    arguments,
  );
  if (programLocationOpenCliRequest != null) {
    return _openProgramLocationJsonResult(
      programLocationOpenCliRequest,
      context,
    );
  }

  return null;
}

CliResult _openBottleLocationJsonResult(
  _BottleLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  return _foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final path = _bottleLocationPath(
        bottle: bottle,
        location: request.location,
      );
      return path.match(
        () => _jsonError(
          exitCode: 65,
          code: 'unsupportedBottleLocation',
          message: 'Bottle location is not supported.',
          extra: <String, Object?>{'location': request.location},
        ),
        (path) => switch (opener.openPath(path)) {
          PathOpenCompleted() => _jsonSuccess(<String, Object?>{
            'openedLocation': <String, Object?>{
              'bottleId': bottle.id.value,
              'location': request.location,
              'path': path,
            },
          }),
          PathOpenFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'bottleLocationOpenFailed',
            message: message,
            extra: <String, Object?>{
              'bottleId': bottle.id.value,
              'location': request.location,
              'path': path,
            },
          ),
        },
      );
    },
  );
}

CliResult _openProgramLocationJsonResult(
  _ProgramLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  return _foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      if (!hasPinnedProgram(bottle, request.programPath)) {
        return _jsonError(
          exitCode: 66,
          code: 'programNotPinned',
          message: 'Program is not pinned.',
          extra: <String, Object?>{'programPath': request.programPath},
        );
      }

      final path = request.programPath;
      return switch (opener.revealPath(path)) {
        PathOpenCompleted() => _jsonSuccess(<String, Object?>{
          'openedProgramLocation': <String, Object?>{
            'bottleId': bottle.id.value,
            'programPath': request.programPath,
            'path': path,
          },
        }),
        PathOpenFailed(:final message) => _jsonError(
          exitCode: 75,
          code: 'programLocationOpenFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': bottle.id.value,
            'programPath': request.programPath,
            'path': path,
          },
        ),
      };
    },
  );
}

CliResult _pathOpenerUnavailableError() {
  return _unavailableJsonError(
    code: 'pathOpenerUnavailable',
    subject: 'Path opener',
  );
}

CliResult? _handleWinetricksVerbCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonWinetricksVerbListCommand(arguments)) {
    return null;
  }

  return _winetricksVerbListJsonResult(
    context.winetricksVerbRepository.listVerbs(),
  );
}

CliResult _winetricksVerbListJsonResult(WinetricksVerbListResult result) {
  return switch (result) {
    WinetricksVerbListCompleted(:final categories) => _jsonSuccess(
      <String, Object?>{
        'winetricks': <String, Object?>{
          'categories': categories
              .map((category) => category.toJson())
              .toList(growable: false),
        },
      },
    ),
    WinetricksVerbListFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksVerbsUnavailable',
      message: message,
    ),
  };
}
