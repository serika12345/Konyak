import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/runtime/runtime_platform.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('resolves the managed runtime identity for supported platforms', () {
    expect(
      managedRuntimePlatform(KonyakPlatform.macos).runtimeId,
      'konyak-macos-wine',
    );
    expect(
      managedRuntimePlatform(KonyakPlatform.linux).runtimeId,
      'konyak-linux-wine',
    );
  });

  test(
    'selects runtimes by platform without exposing platform branches to UI',
    () {
      final runtimes = [
        _runtime(id: 'konyak-macos-wine', platform: 'macos'),
        _runtime(id: 'konyak-linux-wine', platform: 'linux'),
      ];

      final macosSelection = runtimeForPlatformSelection(
        KonyakPlatform.macos,
        runtimes,
      );
      final linuxSelection = runtimeForPlatformSelection(
        KonyakPlatform.linux,
        runtimes,
      );

      expect(switch (macosSelection) {
        RuntimeForPlatformFound(:final runtime) => runtime.id,
        RuntimeForPlatformMissing() => '',
      }, 'konyak-macos-wine');
      expect(switch (linuxSelection) {
        RuntimeForPlatformFound(:final runtime) => runtime.id,
        RuntimeForPlatformMissing() => '',
      }, 'konyak-linux-wine');
      expect(
        runtimesForPlatform(
          KonyakPlatform.linux,
          runtimes,
        ).map((runtime) => runtime.id),
        ['konyak-linux-wine'],
      );
    },
  );

  test('models a missing platform runtime without a nullable result', () {
    final selection = runtimeForPlatformSelection(
      KonyakPlatform.macos,
      const <RuntimeSummary>[],
    );

    expect(switch (selection) {
      RuntimeForPlatformFound() => '',
      RuntimeForPlatformMissing(:final managedRuntime) =>
        managedRuntime.runtimeId,
    }, 'konyak-macos-wine');
  });

  test('upserts runtime summaries without mutating the input list', () {
    final originalMacosRuntime = _runtime(
      id: 'konyak-macos-wine',
      platform: 'macos',
    );
    final replacementMacosRuntime = _runtime(
      id: 'konyak-macos-wine',
      platform: 'macos',
      isInstalled: false,
    );
    final linuxRuntime = _runtime(id: 'konyak-linux-wine', platform: 'linux');
    final runtimes = [originalMacosRuntime];

    final replaced = upsertRuntimeSummary(runtimes, replacementMacosRuntime);
    final appended = upsertRuntimeSummary(runtimes, linuxRuntime);

    expect(runtimes, [originalMacosRuntime]);
    expect(replaced, [replacementMacosRuntime]);
    expect(appended, [originalMacosRuntime, linuxRuntime]);
    expect(replaced.clear, throwsUnsupportedError);
    expect(appended.clear, throwsUnsupportedError);
  });
}

RuntimeSummary _runtime({
  required String id,
  required String platform,
  bool isInstalled = true,
}) {
  return RuntimeSummary(
    id: id,
    name: id,
    platform: platform,
    architecture: 'x86_64',
    runnerKind: 'wine',
    isBundled: false,
    isUpdateable: true,
    isInstalled: isInstalled,
  );
}
