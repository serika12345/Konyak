import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../app_platform.dart';

part 'program_window_probe.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramWindowProbeResult<T> with _$ProgramWindowProbeResult<T> {
  const ProgramWindowProbeResult._();

  factory ProgramWindowProbeResult.available(Set<T> ids) {
    return ProgramWindowProbeResult._available(Set.unmodifiable(ids));
  }

  const factory ProgramWindowProbeResult._available(Set<T> ids) =
      AvailableProgramWindowProbeResult<T>;

  const factory ProgramWindowProbeResult.unavailable() =
      UnavailableProgramWindowProbeResult<T>;
}

abstract interface class ProgramWindowProbe {
  Future<ProgramWindowProbeResult<String>> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  });

  Future<ProgramWindowProbeResult<int>> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  });
}

final class NativeProgramWindowProbe implements ProgramWindowProbe {
  const NativeProgramWindowProbe();

  static const MethodChannel _macosMenuChannel = MethodChannel('konyak/menu');
  static const MethodChannel _linuxWindowChannel = MethodChannel(
    'konyak/linux_window',
  );

  @override
  Future<ProgramWindowProbeResult<String>> visibleExternalWindowIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcessWindows = false,
  }) async {
    if (!platform.isMacOS && !platform.isLinux) {
      return const ProgramWindowProbeResult<String>.unavailable();
    }

    final rootProcessIds = descendantOfProcessIds
        .where((processId) => processId > 0)
        .toSet();
    if (rootProcessIds.isEmpty && !includeWineProcessWindows) {
      return const ProgramWindowProbeResult<String>.unavailable();
    }

    final channel = platform.isMacOS ? _macosMenuChannel : _linuxWindowChannel;

    try {
      final windowIds = await channel.invokeListMethod<String>(
        'visibleExternalWindowIds',
        <String, Object>{
          'descendantOfProcessIds': rootProcessIds.toList(growable: false)
            ..sort(),
          'includeWineProcessWindows': includeWineProcessWindows,
        },
      );
      if (windowIds == null) {
        return const ProgramWindowProbeResult<String>.unavailable();
      }

      return ProgramWindowProbeResult<String>.available(<String>{
        for (final windowId in windowIds)
          if (windowId.trim().isNotEmpty) windowId.trim(),
      });
    } on MissingPluginException {
      return const ProgramWindowProbeResult<String>.unavailable();
    } on PlatformException {
      return const ProgramWindowProbeResult<String>.unavailable();
    }
  }

  @override
  Future<ProgramWindowProbeResult<int>> runningWineProcessIds(
    KonyakPlatform platform, {
    Set<int> descendantOfProcessIds = const <int>{},
    bool includeWineProcesses = false,
  }) async {
    if (!platform.isLinux) {
      return const ProgramWindowProbeResult<int>.unavailable();
    }

    final rootProcessIds = descendantOfProcessIds
        .where((processId) => processId > 0)
        .toSet();
    if (rootProcessIds.isEmpty && !includeWineProcesses) {
      return const ProgramWindowProbeResult<int>.unavailable();
    }

    try {
      final processIds = await _linuxWindowChannel
          .invokeListMethod<int>('runningWineProcessIds', <String, Object>{
            'descendantOfProcessIds': rootProcessIds.toList(growable: false)
              ..sort(),
            'includeWineProcesses': includeWineProcesses,
          });
      if (processIds == null) {
        return const ProgramWindowProbeResult<int>.unavailable();
      }

      return ProgramWindowProbeResult<int>.available(<int>{
        for (final processId in processIds)
          if (processId > 0) processId,
      });
    } on MissingPluginException {
      return const ProgramWindowProbeResult<int>.unavailable();
    } on PlatformException {
      return const ProgramWindowProbeResult<int>.unavailable();
    }
  }
}
