import '../../domain/runtime/runtime_models.dart';
import '../../io/runtime_install_progress_io.dart';
import 'linux_wine_install_requests.dart';

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
