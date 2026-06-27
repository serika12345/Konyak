import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows D3D12 MSVC fixture has pinned build entrypoints', () {
    final cmake = File(
      '../../tests/fixtures/windows/d3d12_minimal_sample/CMakeLists.txt',
    ).readAsStringSync();
    final presets = File(
      '../../tests/fixtures/windows/d3d12_minimal_sample/CMakePresets.json',
    ).readAsStringSync();
    final source = File(
      '../../tests/fixtures/windows/d3d12_minimal_sample/src/main.cpp',
    ).readAsStringSync();
    final buildScript = File(
      '../../scripts/build_d3d12_minimal_sample_windows.ps1',
    ).readAsStringSync();
    final workflow = File(
      '../../.github/workflows/windows-d3d12-fixture-build.yml',
    ).readAsStringSync();
    final macosRuntimeWorkflow = File(
      '../../.github/workflows/macos-runtime-cli-smoke.yml',
    ).readAsStringSync();
    final macosRuntimeSmokeScript = File(
      '../../scripts/run_macos_runtime_cli_smoke.zsh',
    ).readAsStringSync();

    expect(cmake, contains('project(konyak_d3d12_minimal'));
    expect(cmake, contains('d3d12.lib'));
    expect(cmake, contains('dxgi.lib'));
    expect(cmake, contains('MultiThreaded'));
    expect(presets, contains('"generator": "Visual Studio 17 2022"'));
    expect(presets, contains('"architecture": "x64,version=10.0"'));
    expect(presets, contains('"toolset": "v143"'));
    expect(presets, contains('windows-msvc-v143-x64-release'));
    expect(source, contains('D3D12CreateDevice'));
    expect(source, contains('CreateSwapChainForHwnd'));
    expect(source, contains('KONYAK_D3D12_MINIMAL_SAMPLE_OK'));
    expect(source, contains('konyak-d3d12-minimal-sample-ok.txt'));
    expect(buildScript, contains('vswhere.exe'));
    expect(buildScript, contains('-version "[17.0,18.0)"'));
    expect(buildScript, contains('windows-msvc-v143-x64-release'));
    expect(workflow, contains('runs-on: windows-2022'));
    expect(
      workflow,
      contains('./scripts/build_d3d12_minimal_sample_windows.ps1'),
    );
    expect(workflow, contains('actions/upload-artifact@v4'));
    expect(macosRuntimeWorkflow, contains('build-d3d12-fixture:'));
    expect(macosRuntimeWorkflow, contains('needs: build-d3d12-fixture'));
    expect(
      macosRuntimeWorkflow,
      contains('konyak-d3d12-minimal-sample-windows-x64'),
    );
    expect(
      macosRuntimeWorkflow,
      contains('KONYAK_MACOS_RUNTIME_CLI_SMOKE_D3D12_SAMPLE_EXE'),
    );
    expect(
      macosRuntimeSmokeScript,
      contains('KONYAK_MACOS_RUNTIME_CLI_SMOKE_D3D12_SAMPLE_EXE'),
    );
    expect(macosRuntimeSmokeScript, contains('run_d3d12_sample_smoke'));
    expect(macosRuntimeSmokeScript, contains('macos_d3dmetal_available'));
    expect(macosRuntimeSmokeScript, contains('D3D12 visible sample backend:'));
    expect(macosRuntimeSmokeScript, contains('d3dmetal)'));
    expect(
      macosRuntimeSmokeScript,
      contains('.bottle.runtimeSettings.dxrEnabled == true'),
    );
    expect(macosRuntimeSmokeScript, contains('d3d12-msvc-visible-sample'));
    expect(
      macosRuntimeSmokeScript,
      contains('konyak-d3d12-minimal-sample-ok.txt'),
    );
    expect(
      macosRuntimeSmokeScript,
      contains('wait_for_visible_sample_sentinel'),
    );
    expect(macosRuntimeSmokeScript, contains('"arguments":"--frames 120"'));
  });
}
