part of '../../../konyak_cli.dart';

class MacosSetupStatus {
  const MacosSetupStatus({
    required this.isSupported,
    required this.rosetta,
    required this.runtime,
  });

  final bool isSupported;
  final RosettaSetupStatus rosetta;
  final RuntimeSetupStatus runtime;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isSupported': isSupported,
      'rosetta': rosetta.toJson(),
      'runtime': runtime.toJson(),
    };
  }
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isRequired': isRequired,
      'isInstalled': isInstalled,
      'installCommand': installCommand,
    };
  }
}

class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.runtimeId,
    required this.isInstalled,
  });

  final String runtimeId;
  final bool isInstalled;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isInstalled': isInstalled,
    };
  }
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
      hostPlatform: _currentHostPlatform(),
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
      macosWineRuntimeId,
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
