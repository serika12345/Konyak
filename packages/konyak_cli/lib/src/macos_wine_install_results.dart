part of '../konyak_cli.dart';

sealed class MacosWineInstallResult {
  const MacosWineInstallResult();
}

class MacosWineInstallCompleted extends MacosWineInstallResult {
  const MacosWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class MacosWineInstallFailed extends MacosWineInstallResult {
  const MacosWineInstallFailed(this.message);

  final String message;
}

abstract interface class MacosWineInstaller {
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}
