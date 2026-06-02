part of '../../../konyak_cli.dart';

class DartIoMacosWineRuntimeValidator implements RuntimeValidator {
  const DartIoMacosWineRuntimeValidator({
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.executableProbe = const DartIoRuntimeExecutableProbe(),
  });

  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;
  final RuntimeExecutableProbe executableProbe;

  @override
  RuntimeValidationResult validate(String runtimeId) {
    final runtime = _runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    return runtime.match(
      () => RuntimeValidationRuntimeNotFound(runtimeId),
      _validateRuntime,
    );
  }

  RuntimeValidationResult _validateRuntime(RuntimeRecord runtime) {
    final runtimeRoot = runtime.libraryPath.toNullable();
    final executablePath = runtime.executablePath.toNullable();
    if (runtimeRoot == null || executablePath == null) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: const [
            RuntimeValidationCheck(
              id: 'runtime-layout',
              name: 'Runtime layout',
              isRequired: true,
              isPassed: false,
              message: 'Runtime record is missing layout paths.',
            ),
          ],
        ),
      );
    }

    final checks = <RuntimeValidationCheck>[
      _runtimePathCheck(
        id: 'runtime-root',
        name: 'Runtime root',
        path: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimePathCheck(
        id: 'wine-executable',
        name: 'Wine executable',
        path: executablePath,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimeAnyPathCheck(
        id: 'loader-dylibs',
        name: 'Wine loader libraries',
        paths: _macosWineLoaderLibraryPaths(runtimeRoot),
        fileStatusProbe: fileStatusProbe,
      ),
    ];

    if (!checks.every((check) => !check.isRequired || check.isPassed)) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: checks,
        ),
      );
    }

    final loaderResult = executableProbe.run(
      executable: executablePath,
      arguments: const ['--version'],
      environment: ProgramRunEnvironment(<String, String>{
        'DYLD_LIBRARY_PATH': _joinPath(runtimeRoot, const ['lib']),
      }),
      workingDirectory: _dirname(executablePath),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wine64 --version completed.'
          : _runtimeLoaderFailureMessage(loaderResult),
    );
    final completedChecks = <RuntimeValidationCheck>[...checks, loaderCheck];

    return RuntimeValidationCompleted(
      RuntimeValidationRecord(
        runtimeId: runtime.id,
        isValid: completedChecks.every(
          (check) => !check.isRequired || check.isPassed,
        ),
        checks: completedChecks,
      ),
    );
  }
}
