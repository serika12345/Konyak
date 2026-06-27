part of '../../../konyak_cli.dart';

class DartIoMacosWineRuntimeValidator implements RuntimeValidator {
  const DartIoMacosWineRuntimeValidator({
    required this.runtimeCatalog,
    this.environment = const HostEnvironment.empty(),
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.executableProbe = const DartIoRuntimeExecutableProbe(),
  });

  final RuntimeCatalog runtimeCatalog;
  final HostEnvironment environment;
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
    final runtimeRoot = runtime.libraryPath.toNullable()?.value;
    final executablePath = runtime.executablePath.toNullable()?.value;
    if (runtimeRoot == null || executablePath == null) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id.value,
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

    if (runtime.id.value == linuxWineRuntimeId) {
      return _validateLinuxRuntime(
        runtime: runtime,
        runtimeRoot: runtimeRoot,
        executablePath: executablePath,
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
      _runtimeStackCompletenessCheck(runtime.stack),
    ];

    if (!checks.every((check) => !check.isRequired || check.isPassed)) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id.value,
          isValid: false,
          checks: checks,
        ),
      );
    }

    final loaderResult = executableProbe.run(
      executable: executablePath,
      arguments: const ['--version'],
      environment: ProgramRunEnvironment(<String, String>{
        'WINELOADER': executablePath,
        'WINESERVER': _joinPath(runtimeRoot, const ['bin', 'wineserver']),
        'WINEDLLPATH': _macosWineWindowsDllPaths(runtimeRoot).join(':'),
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
          ? 'wineloader --version completed.'
          : _runtimeLoaderFailureMessage(loaderResult),
    );
    final completedChecks = <RuntimeValidationCheck>[...checks, loaderCheck];

    return RuntimeValidationCompleted(
      RuntimeValidationRecord(
        runtimeId: runtime.id.value,
        isValid: completedChecks.every(
          (check) => !check.isRequired || check.isPassed,
        ),
        checks: completedChecks,
      ),
    );
  }

  RuntimeValidationResult _validateLinuxRuntime({
    required RuntimeRecord runtime,
    required String runtimeRoot,
    required String executablePath,
  }) {
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
      _runtimeStackCompletenessCheck(runtime.stack),
    ];

    if (!checks.every((check) => !check.isRequired || check.isPassed)) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id.value,
          isValid: false,
          checks: checks,
        ),
      );
    }

    final loaderResult = executableProbe.run(
      executable: executablePath,
      arguments: const ['--version'],
      environment: _linuxRuntimeEnvironment(environment),
      workingDirectory: _dirname(executablePath),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wine --version completed.'
          : _runtimeLoaderFailureMessage(loaderResult),
    );
    final completedChecks = <RuntimeValidationCheck>[...checks, loaderCheck];

    return RuntimeValidationCompleted(
      RuntimeValidationRecord(
        runtimeId: runtime.id.value,
        isValid: completedChecks.every(
          (check) => !check.isRequired || check.isPassed,
        ),
        checks: completedChecks,
      ),
    );
  }
}

RuntimeValidationCheck _runtimeStackCompletenessCheck(
  Option<RuntimeStack> stackOption,
) {
  final stack = stackOption.toNullable();
  if (stack == null) {
    return const RuntimeValidationCheck(
      id: 'runtime-stack',
      name: 'Runtime stack',
      isRequired: true,
      isPassed: false,
      message: 'Runtime stack metadata is missing.',
    );
  }

  if (stack.isComplete) {
    return const RuntimeValidationCheck(
      id: 'runtime-stack',
      name: 'Runtime stack',
      isRequired: true,
      isPassed: true,
      message: 'Runtime stack is complete.',
    );
  }

  return RuntimeValidationCheck(
    id: 'runtime-stack',
    name: 'Runtime stack',
    isRequired: true,
    isPassed: false,
    message:
        'Runtime stack is incomplete: ${_incompleteMacosWineStackSummary(stack)}.',
  );
}
