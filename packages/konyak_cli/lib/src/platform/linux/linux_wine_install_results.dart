part of '../../../konyak_cli.dart';

sealed class LinuxWineInstallResult {
  const LinuxWineInstallResult();
}

class LinuxWineInstallCompleted extends LinuxWineInstallResult {
  const LinuxWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class LinuxWineInstallFailed extends LinuxWineInstallResult {
  const LinuxWineInstallFailed(this.message);

  final String message;
}

abstract interface class LinuxWineInstaller {
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}
