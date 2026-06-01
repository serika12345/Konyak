import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/runtime/runtime_platform.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('resolves the managed runtime identity for supported platforms', () {
    expect(
      managedRuntimePlatform(KonyakPlatform.macos)?.runtimeId,
      'konyak-macos-wine',
    );
    expect(
      managedRuntimePlatform(KonyakPlatform.linux)?.runtimeId,
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

      expect(
        runtimeForPlatform(KonyakPlatform.macos, runtimes)?.id,
        'konyak-macos-wine',
      );
      expect(
        runtimeForPlatform(KonyakPlatform.linux, runtimes)?.id,
        'konyak-linux-wine',
      );
      expect(
        runtimesForPlatform(
          KonyakPlatform.linux,
          runtimes,
        ).map((runtime) => runtime.id),
        ['konyak-linux-wine'],
      );
    },
  );
}

RuntimeSummary _runtime({required String id, required String platform}) {
  return RuntimeSummary(
    id: id,
    name: id,
    platform: platform,
    architecture: 'x86_64',
    runnerKind: 'wine',
    isBundled: false,
    isUpdateable: true,
    isInstalled: true,
  );
}
