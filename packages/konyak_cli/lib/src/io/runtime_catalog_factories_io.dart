import 'dart:io';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_catalogs.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_validation_support.dart';
import 'platform_host_paths.dart';
import 'runtime_platform_records.dart';
import 'runtime_probes.dart';

class MacosWineRuntimeCatalog implements RuntimeCatalog {
  MacosWineRuntimeCatalog({
    required this.hostPlatform,
    required this.environment,
    required this.fileStatusProbe,
    required this.runtimeStackVersionProbe,
  });

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final FileStatusProbe fileStatusProbe;
  final RuntimeStackVersionProbe runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => const <RuntimeRecord>[],
    };
  }
}

class KonyakRuntimeCatalog implements RuntimeCatalog {
  KonyakRuntimeCatalog({
    required this.hostPlatform,
    required this.environment,
    required this.fileStatusProbe,
    required this.runtimeStackVersionProbe,
  });

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final FileStatusProbe fileStatusProbe;
  final RuntimeStackVersionProbe runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => <RuntimeRecord>[
        linuxWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ],
    };
  }
}

MacosWineRuntimeCatalog currentMacosWineRuntimeCatalog() {
  return MacosWineRuntimeCatalog(
    hostPlatform: currentHostPlatform(),
    environment: HostEnvironment(Platform.environment),
    fileStatusProbe: const DartIoFileStatusProbe(),
    runtimeStackVersionProbe: const DartIoRuntimeStackVersionProbe(),
  );
}

KonyakRuntimeCatalog currentKonyakRuntimeCatalog() {
  return KonyakRuntimeCatalog(
    hostPlatform: currentHostPlatform(),
    environment: HostEnvironment(Platform.environment),
    fileStatusProbe: const DartIoFileStatusProbe(),
    runtimeStackVersionProbe: const DartIoRuntimeStackVersionProbe(),
  );
}
