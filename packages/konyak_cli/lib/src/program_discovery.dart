part of '../konyak_cli.dart';

class DartIoWinetricksVerbRepository implements WinetricksVerbRepository {
  const DartIoWinetricksVerbRepository({
    required this.runtimeRoot,
    this.hostPlatform = KonyakHostPlatform.macos,
    this.lister = const DartIoWinetricksVerbLister(),
    this.scriptInstaller = const DartIoWinetricksScriptInstaller(),
  });

  factory DartIoWinetricksVerbRepository.current({
    Map<String, String>? environment,
    KonyakHostPlatform? hostPlatform,
    WinetricksVerbLister lister = const DartIoWinetricksVerbLister(),
    WinetricksScriptInstaller scriptInstaller =
        const DartIoWinetricksScriptInstaller(),
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    final resolvedHostPlatform = hostPlatform ?? _currentHostPlatform();
    return DartIoWinetricksVerbRepository(
      runtimeRoot: switch (resolvedHostPlatform) {
        KonyakHostPlatform.macos => _macosWineRuntimeRoot(resolvedEnvironment),
        KonyakHostPlatform.linux => _linuxWineRuntimeRoot(resolvedEnvironment),
      },
      hostPlatform: resolvedHostPlatform,
      lister: lister,
      scriptInstaller: scriptInstaller,
    );
  }

  final String runtimeRoot;
  final KonyakHostPlatform hostPlatform;
  final WinetricksVerbLister lister;
  final WinetricksScriptInstaller scriptInstaller;

  @override
  WinetricksVerbListResult listVerbs() {
    if (hostPlatform == KonyakHostPlatform.linux) {
      final managedExecutable = _joinPath(runtimeRoot, const ['winetricks']);
      return lister.listVerbs(
        executable: File(managedExecutable).existsSync()
            ? managedExecutable
            : 'winetricks',
      );
    }

    final verbsFile = File(_joinPath(runtimeRoot, const ['verbs.txt']));
    if (verbsFile.existsSync()) {
      try {
        return WinetricksVerbListCompleted(
          categories: parseWinetricksVerbs(verbsFile.readAsStringSync()),
        );
      } on FileSystemException catch (error) {
        return WinetricksVerbListFailed(error.message);
      }
    }

    final executable = _joinPath(runtimeRoot, const ['winetricks']);
    final installResult = scriptInstaller.installIfMissing(
      executable: executable,
    );
    switch (installResult) {
      case WinetricksScriptInstallCompleted():
        return lister.listVerbs(executable: executable);
      case WinetricksScriptInstallFailed(:final message):
        return WinetricksVerbListFailed(message);
    }
  }
}

class DartIoWinetricksScriptInstaller implements WinetricksScriptInstaller {
  const DartIoWinetricksScriptInstaller();

  @override
  WinetricksScriptInstallResult installIfMissing({required String executable}) {
    final target = File(executable);
    if (target.existsSync()) {
      return const WinetricksScriptInstallCompleted();
    }

    final temporaryPath = '$executable.download';
    final temporaryFile = File(temporaryPath);

    try {
      target.parent.createSync(recursive: true);
      final downloadResult = Process.runSync('curl', <String>[
        '--fail',
        '--location',
        '--silent',
        '--show-error',
        '--output',
        temporaryPath,
        winetricksScriptUrl,
      ], runInShell: false);

      if (downloadResult.exitCode != 0) {
        _deleteFileIfPresent(temporaryFile);
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('download Winetricks', downloadResult),
        );
      }

      temporaryFile.renameSync(executable);

      final chmodResult = Process.runSync('chmod', <String>[
        '755',
        executable,
      ], runInShell: false);
      if (chmodResult.exitCode != 0) {
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('mark Winetricks executable', chmodResult),
        );
      }

      return const WinetricksScriptInstallCompleted();
    } on ProcessException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    } on FileSystemException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(error.message);
    }
  }
}

void _deleteFileIfPresent(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup only; the original failure is more useful.
  }
}

class DartIoWinetricksVerbLister implements WinetricksVerbLister {
  const DartIoWinetricksVerbLister();

  @override
  WinetricksVerbListResult listVerbs({required String executable}) {
    try {
      final result = Process.runSync(
        executable,
        const <String>['list-all'],
        environment: const <String, String>{'LANG': 'C'},
        runInShell: false,
      );

      if (result.exitCode != 0) {
        return WinetricksVerbListFailed(
          _commandFailureMessage('winetricks list-all', result),
        );
      }

      return WinetricksVerbListCompleted(
        categories: parseWinetricksVerbs(_processOutputToString(result.stdout)),
      );
    } on ProcessException catch (error) {
      return WinetricksVerbListFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    }
  }
}

class DartIoBottleProgramRepository implements BottleProgramRepository {
  const DartIoBottleProgramRepository({
    ProgramMetadataExtractor metadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : _metadataExtractor = metadataExtractor;

  final ProgramMetadataExtractor _metadataExtractor;

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    final programs = <BottleProgramRecord>[];
    for (final source in _bottleStartMenuSources(bottle)) {
      final directory = Directory(source.path);
      if (!directory.existsSync()) {
        continue;
      }

      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !_isShortcutPath(entity.path)) {
          continue;
        }

        final name = _shortcutProgramName(entity.path);
        final id = _uniqueProgramId(
          baseId: _bottleIdFromName(name),
          existing: programs,
        );
        final metadata = _metadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: entity.path,
          ),
        );
        programs.add(
          BottleProgramRecord(
            id: id,
            name: name,
            path: entity.path,
            source: source.id,
            metadata: metadata,
          ),
        );
      }
    }

    for (final pinnedProgram in bottle.pinnedPrograms) {
      final id = _uniqueProgramId(
        baseId: _bottleIdFromName(pinnedProgram.name),
        existing: programs,
      );
      final metadata = _metadataExtractor.extract(
        bottle: bottle,
        programPath: _metadataProgramPath(
          bottle: bottle,
          programPath: pinnedProgram.path,
        ),
      );
      programs.add(
        BottleProgramRecord(
          id: id,
          name: pinnedProgram.name,
          path: pinnedProgram.path,
          source: 'pinned',
          metadata: metadata,
        ),
      );
    }

    programs.sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(programs);
  }
}

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  ProgramMetadataRecord? extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return null;
      }

      final image = _PortableExecutableImage.parse(file.readAsBytesSync());
      if (image == null) {
        return null;
      }

      final versionStrings = _peVersionStrings(image);
      final iconPath = _extractPeIcon(
        image: image,
        bottle: bottle,
        programPath: programPath,
        fileStat: file.statSync(),
      );
      final metadata = ProgramMetadataRecord(
        architecture: image.architecture,
        fileDescription: versionStrings['FileDescription'],
        productName: versionStrings['ProductName'],
        companyName: versionStrings['CompanyName'],
        fileVersion: versionStrings['FileVersion'],
        productVersion: versionStrings['ProductVersion'],
        iconPath: iconPath,
      );

      return metadata.isEmpty ? null : metadata;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}

class DartIoBottlePrefixInitializer implements BottlePrefixInitializer {
  const DartIoBottlePrefixInitializer({
    required this.programRunPlanner,
    required this.programRunner,
  });

  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner programRunner;

  @override
  BottlePrefixInitializationResult initialize(BottleRecord bottle) {
    final request = programRunPlanner.planPrefixInitialization(bottle: bottle);
    final result = programRunner.run(request);

    return switch (result) {
      ProgramRunCompleted(:final processExitCode) when processExitCode == 0 =>
        const BottlePrefixInitialized(),
      ProgramRunCompleted(:final processExitCode) =>
        BottlePrefixInitializationFailed(
          'wineboot exited with code $processExitCode. See ${request.logPath}.',
        ),
      ProgramRunFailed(:final message) => BottlePrefixInitializationFailed(
        message,
      ),
    };
  }
}
