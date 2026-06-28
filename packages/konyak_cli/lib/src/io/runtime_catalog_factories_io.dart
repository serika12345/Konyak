part of '../../konyak_cli.dart';

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
