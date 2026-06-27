import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/dialogs/app_settings_runtime_view_model.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('resolves runtime section metadata by platform', () {
    expect(showsRuntimeSection(KonyakPlatform.macos), isTrue);
    expect(runtimeSectionPlatform(KonyakPlatform.macos), 'macos');

    expect(showsRuntimeSection(KonyakPlatform.linux), isTrue);
    expect(runtimeSectionPlatform(KonyakPlatform.linux), 'linux');
  });

  test('selects the runtime stack for the requested platform', () {
    final selection = resolveRuntimeSectionState(
      runtimes: [
        _runtime(id: 'plain', platform: 'linux', stack: null),
        _runtime(
          id: 'stacked',
          platform: 'linux',
          isInstalled: true,
          stack: _stack(isComplete: true),
        ),
        _runtime(
          id: 'macos',
          platform: 'macos',
          isInstalled: true,
          stack: _stack(isComplete: true),
        ),
      ],
      platform: 'linux',
    );

    switch (selection) {
      case RuntimeSectionAvailable(
        :final runtime,
        :final stack,
        :final shouldOfferInstall,
        :final installButtonLabel,
      ):
        expect(runtime.id, 'stacked');
        expect(stack.isComplete, isTrue);
        expect(shouldOfferInstall, isFalse);
        expect(installButtonLabel, RuntimeInstallButtonLabel.repair);
      case RuntimeSectionUnavailable():
        fail('Expected a selected runtime stack.');
    }
  });

  test('offers repair for incomplete installed runtimes', () {
    final selection = resolveRuntimeSectionState(
      runtimes: [
        _runtime(
          id: 'linux',
          platform: 'linux',
          isInstalled: true,
          stack: _stack(isComplete: false),
        ),
      ],
      platform: 'linux',
    );

    switch (selection) {
      case RuntimeSectionAvailable(
        :final shouldOfferInstall,
        :final installButtonLabel,
      ):
        expect(shouldOfferInstall, isTrue);
        expect(installButtonLabel, RuntimeInstallButtonLabel.repair);
      case RuntimeSectionUnavailable():
        fail('Expected an incomplete runtime stack.');
    }
  });

  test(
    'labels optional missing runtime components as partial without repair',
    () {
      final stack = RuntimeStackSummary(
        id: 'stack',
        name: 'Stack',
        compatibilityTarget: 'stack',
        isComplete: true,
        components: [
          _component(isInstalled: true, version: '1.0'),
          RuntimeStackComponentSummary(
            id: 'gptk-d3dmetal',
            name: 'GPTK/D3DMetal',
            role: 'd3d12-metal-translation',
            isRequired: false,
            isInstalled: false,
            paths: const <String>['/runtime/components/gptk-d3dmetal'],
            missingPaths: const <String>['/runtime/components/gptk-d3dmetal'],
          ),
        ],
      );
      final selection = resolveRuntimeSectionState(
        runtimes: [
          _runtime(
            id: 'macos',
            platform: 'macos',
            isInstalled: true,
            stack: stack,
          ),
        ],
        platform: 'macos',
      );

      expect(runtimeStackStatusLabel(stack), RuntimeStackStatusLabel.partial);
      switch (selection) {
        case RuntimeSectionAvailable(:final shouldOfferInstall):
          expect(shouldOfferInstall, isFalse);
        case RuntimeSectionUnavailable():
          fail('Expected a selected runtime stack.');
      }
    },
  );
}

RuntimeSummary _runtime({
  required String id,
  required String platform,
  RuntimeStackSummary? stack,
  bool? isInstalled,
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
    stack: stack,
  );
}

RuntimeStackSummary _stack({required bool isComplete}) {
  return RuntimeStackSummary(
    id: 'stack',
    name: 'Stack',
    compatibilityTarget: 'stack',
    isComplete: isComplete,
    components: [_component(isInstalled: isComplete, version: '1.0')],
  );
}

RuntimeStackComponentSummary _component({
  required bool isInstalled,
  required String? version,
}) {
  return RuntimeStackComponentSummary(
    id: 'wine',
    name: 'Wine',
    role: 'windows-runner',
    isRequired: true,
    isInstalled: isInstalled,
    paths: const <String>['/runtime/bin/wine'],
    missingPaths: isInstalled ? const <String>[] : const <String>['missing'],
    version: version,
  );
}
