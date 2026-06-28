part of '../../konyak_cli.dart';

class MacosWineRuntimeCatalog implements RuntimeCatalog {
  MacosWineRuntimeCatalog({
    required this.hostPlatform,
    required this.environment,
    required FileStatusProbe fileStatusProbe,
    required RuntimeStackVersionProbe runtimeStackVersionProbe,
  }) : _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
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
    required FileStatusProbe fileStatusProbe,
    required RuntimeStackVersionProbe runtimeStackVersionProbe,
  }) : _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => <RuntimeRecord>[
        _linuxWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
    };
  }
}

MacosWineRuntimeCatalog currentMacosWineRuntimeCatalog() {
  return MacosWineRuntimeCatalog(
    hostPlatform: _currentHostPlatform(),
    environment: HostEnvironment(Platform.environment),
    fileStatusProbe: const DartIoFileStatusProbe(),
    runtimeStackVersionProbe: const DartIoRuntimeStackVersionProbe(),
  );
}

KonyakRuntimeCatalog currentKonyakRuntimeCatalog() {
  return KonyakRuntimeCatalog(
    hostPlatform: _currentHostPlatform(),
    environment: HostEnvironment(Platform.environment),
    fileStatusProbe: const DartIoFileStatusProbe(),
    runtimeStackVersionProbe: const DartIoRuntimeStackVersionProbe(),
  );
}
