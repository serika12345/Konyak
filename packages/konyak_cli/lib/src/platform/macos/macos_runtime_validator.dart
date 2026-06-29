import 'package:fpdart/fpdart.dart';

import '../../domain/program/program_run_environment.dart';
import '../../domain/runtime/host_environment.dart';
import '../../domain/runtime/runtime_catalogs.dart';
import '../../domain/runtime/runtime_models.dart';
import '../../domain/runtime/runtime_update_support.dart';
import '../../domain/runtime/runtime_validation_models.dart';
import '../../domain/runtime/runtime_validation_support.dart';
import '../../domain/runtime/wine_runtime_paths.dart';
import '../../domain/shared/domain_value_objects.dart';
import '../../io/macos_wine_archive_installation.dart';
import '../../io/runtime_executable_probe.dart';
import '../../io/runtime_probes.dart';
import '../../shared/common_helpers.dart';
import '../../shared/model_constants.dart';
import '../platform_terminal_commands.dart';
import 'macos_program_run_requests.dart';

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
  RuntimeValidationResult validate(RuntimeId runtimeId) {
    final runtime = runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    return runtime.match(
      () => RuntimeValidationResult.runtimeNotFound(runtimeId),
      validateRuntime,
    );
  }

  RuntimeValidationResult validateRuntime(RuntimeRecord runtime) {
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
      return validateLinuxRuntime(
        runtime: runtime,
        runtimeRoot: runtimeRoot,
        executablePath: executablePath,
      );
    }

    final checks = <RuntimeValidationCheck>[
      runtimePathCheck(
        id: 'runtime-root',
        name: 'Runtime root',
        path: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
      ),
      runtimePathCheck(
        id: 'wine-executable',
        name: 'Wine executable',
        path: executablePath,
        fileStatusProbe: fileStatusProbe,
      ),
      runtimeAnyPathCheck(
        id: 'loader-dylibs',
        name: 'Wine loader libraries',
        paths: macosWineLoaderLibraryPaths(runtimeRoot),
        fileStatusProbe: fileStatusProbe,
      ),
      runtimeStackCompletenessCheck(runtime.stack),
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
      executable: ProgramExecutable(executablePath),
      arguments: ProgramRunArguments(const <String>['--version']),
      environment: ProgramRunEnvironment(<String, String>{
        'WINELOADER': executablePath,
        'WINESERVER': joinPath(runtimeRoot, const ['bin', 'wineserver']),
        'WINEDLLPATH': macosWineWindowsDllPaths(runtimeRoot).join(':'),
        'DYLD_LIBRARY_PATH': joinPath(runtimeRoot, const ['lib']),
      }),
      workingDirectory: ProgramWorkingDirectoryPath(dirname(executablePath)),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wineloader --version completed.'
          : runtimeLoaderFailureMessage(loaderResult),
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

  RuntimeValidationResult validateLinuxRuntime({
    required RuntimeRecord runtime,
    required String runtimeRoot,
    required String executablePath,
  }) {
    final checks = <RuntimeValidationCheck>[
      runtimePathCheck(
        id: 'runtime-root',
        name: 'Runtime root',
        path: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
      ),
      runtimePathCheck(
        id: 'wine-executable',
        name: 'Wine executable',
        path: executablePath,
        fileStatusProbe: fileStatusProbe,
      ),
      runtimeStackCompletenessCheck(runtime.stack),
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
      executable: ProgramExecutable(executablePath),
      arguments: ProgramRunArguments(const <String>['--version']),
      environment: linuxRuntimeEnvironment(environment),
      workingDirectory: ProgramWorkingDirectoryPath(dirname(executablePath)),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wine --version completed.'
          : runtimeLoaderFailureMessage(loaderResult),
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

RuntimeValidationCheck runtimeStackCompletenessCheck(
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
        'Runtime stack is incomplete: ${incompleteMacosWineStackSummary(stack)}.',
  );
}
