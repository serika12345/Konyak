import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/programs/program_window_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native Linux window probe asks the Linux window channel', () async {
    const channel = MethodChannel('konyak/linux_window');
    final methodCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methodCalls.add(call);
          return <String>['wine-window-1', ''];
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final windowIds = await const NativeProgramWindowProbe()
        .visibleExternalWindowIds(
          KonyakPlatform.linux,
          descendantOfProcessIds: <int>{4242, -1},
          includeWineProcessWindows: true,
        );

    expect(windowIds, const <String>{'wine-window-1'});
    expect(methodCalls, hasLength(1));
    expect(methodCalls.single.method, 'visibleExternalWindowIds');
    expect(methodCalls.single.arguments, {
      'descendantOfProcessIds': <int>[4242],
      'includeWineProcessWindows': true,
    });
  });

  test('native Linux process probe asks the Linux window channel', () async {
    const channel = MethodChannel('konyak/linux_window');
    final methodCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methodCalls.add(call);
          return <int>[777, -1];
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final processIds = await const NativeProgramWindowProbe()
        .runningWineProcessIds(
          KonyakPlatform.linux,
          descendantOfProcessIds: <int>{4242, -1},
          includeWineProcesses: true,
        );

    expect(processIds, const <int>{777});
    expect(methodCalls, hasLength(1));
    expect(methodCalls.single.method, 'runningWineProcessIds');
    expect(methodCalls.single.arguments, {
      'descendantOfProcessIds': <int>[4242],
      'includeWineProcesses': true,
    });
  });
}
