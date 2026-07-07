import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows DLSS MetalFX preflight fixture has pinned entrypoints', () {
    final cmake = File(
      '../../tests/fixtures/windows/dlss_metalfx_preflight/CMakeLists.txt',
    ).readAsStringSync();
    final presets = File(
      '../../tests/fixtures/windows/dlss_metalfx_preflight/CMakePresets.json',
    ).readAsStringSync();
    final source = File(
      '../../tests/fixtures/windows/dlss_metalfx_preflight/src/main.cpp',
    ).readAsStringSync();
    final buildScript = File(
      '../../scripts/build_dlss_metalfx_preflight_windows.ps1',
    ).readAsStringSync();
    final workflow = File(
      '../../.github/workflows/windows-dlss-metalfx-preflight-build.yml',
    ).readAsStringSync();
    final macosSmokeScript = File(
      '../../scripts/run_macos_dlss_metalfx_cli_smoke.zsh',
    ).readAsStringSync();
    final proofDoc = File(
      '../../docs/dlss-metalfx-render-proof.md',
    ).readAsStringSync();

    expect(cmake, contains('project(konyak_dlss_metalfx_preflight'));
    expect(cmake, contains('d3d12.lib'));
    expect(cmake, contains('dxgi.lib'));
    expect(cmake, contains('MultiThreaded'));
    expect(presets, contains('"generator": "Visual Studio 17 2022"'));
    expect(presets, contains('windows-msvc-v143-x64-release'));
    expect(source, contains('D3D12CreateDevice'));
    expect(source, contains('CreateSwapChainForHwnd'));
    expect(source, contains('LoadLibraryW(L"nvngx.dll")'));
    expect(source, contains('LoadLibraryW(L"nvapi64.dll")'));
    expect(source, contains('--probe-nv-shims-before-d3d12'));
    expect(source, contains('--probe-nv-shims-after-d3d12'));
    expect(source, contains('nv_shim_probe_phase='));
    expect(source, contains('D3DM_ENABLE_METALFX'));
    expect(source, contains('KONYAK_DLSS_METALFX_PREFLIGHT_OK'));
    expect(source, contains('konyak-dlss-metalfx-preflight-ok.txt'));
    expect(buildScript, contains('vswhere.exe'));
    expect(buildScript, contains('windows-msvc-v143-x64-release'));
    expect(workflow, contains('runs-on: windows-2022'));
    expect(
      workflow,
      contains('./scripts/build_dlss_metalfx_preflight_windows.ps1'),
    );
    expect(workflow, contains('konyak-dlss-metalfx-preflight-windows-x64'));
    expect(
      macosSmokeScript,
      contains('KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE'),
    );
    expect(macosSmokeScript, contains('install-gptk-wine'));
    expect(macosSmokeScript, contains('gptkWineInstall.componentId'));
    expect(macosSmokeScript, contains('D3DM_ENABLE_METALFX'));
    expect(macosSmokeScript, contains('run-program'));
    expect(macosSmokeScript, contains('dlssMetalFx'));
    expect(proofDoc, contains('user-provided DLSS-capable Windows program'));
    expect(proofDoc, contains('run-program --json'));
  });
}
