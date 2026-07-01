import 'package:fpdart/fpdart.dart';

import '../../domain/program/program_runner.dart';
import '../../domain/runtime/runtime_catalogs.dart';
import '../../domain/runtime/runtime_update_support.dart';
import '../../domain/runtime/runtime_validation_support.dart';
import '../../domain/shared/domain_value_objects.dart';
import '../../io/platform_host_paths.dart';
import '../../io/runtime_probes.dart';
import '../../shared/model_constants.dart';

class MacosSetupStatus {
  const MacosSetupStatus({
    required this.isSupported,
    required this.rosetta,
    required this.runtime,
  });

  final bool isSupported;
  final RosettaSetupStatus rosetta;
  final RuntimeSetupStatus runtime;
}

class RosettaSetupStatus {
  RosettaSetupStatus({
    required this.isRequired,
    required this.isInstalled,
    required List<String> installCommand,
  }) : installCommand = List.unmodifiable(installCommand);

  final bool isRequired;
  final bool isInstalled;
  final List<String> installCommand;
}

class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.runtimeId,
    required this.isInstalled,
  });

  final String runtimeId;
  final bool isInstalled;
}

sealed class MacosSetupCheckResult {
  const MacosSetupCheckResult();
}

class MacosSetupCheckCompleted extends MacosSetupCheckResult {
  const MacosSetupCheckCompleted(this.status);

  final MacosSetupStatus status;
}

class MacosSetupCheckFailed extends MacosSetupCheckResult {
  const MacosSetupCheckFailed(this.message);

  final String message;
}

abstract interface class MacosSetupChecker {
  MacosSetupCheckResult check();
}

class DartIoMacosSetupChecker implements MacosSetupChecker {
  const DartIoMacosSetupChecker({
    required this.hostPlatform,
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
  });

  factory DartIoMacosSetupChecker.current(RuntimeCatalog runtimeCatalog) {
    return DartIoMacosSetupChecker(
      hostPlatform: currentHostPlatform(),
      runtimeCatalog: runtimeCatalog,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;

  @override
  MacosSetupCheckResult check() {
    final runtime = runtimeById(
      runtimeCatalog.listRuntimes(),
      RuntimeId(macosWineRuntimeId),
    );

    return MacosSetupCheckCompleted(
      MacosSetupStatus(
        isSupported: hostPlatform == KonyakHostPlatform.macos,
        rosetta: RosettaSetupStatus(
          isRequired: hostPlatform == KonyakHostPlatform.macos,
          isInstalled: fileStatusProbe.exists(rosettaRuntimePath),
          installCommand: rosettaInstallCommand,
        ),
        runtime: RuntimeSetupStatus(
          runtimeId: macosWineRuntimeId,
          isInstalled: runtime
              .flatMap((runtime) => runtime.isInstalled)
              .getOrElse(() => false),
        ),
      ),
    );
  }
}
