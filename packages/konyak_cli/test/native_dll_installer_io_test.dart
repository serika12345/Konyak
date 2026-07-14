import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/file_digest_io.dart';
import 'package:konyak_cli/src/io/native_dll_installer_io.dart';
import 'package:test/test.dart';

void main() {
  test('installs a validated x86 PE atomically without changing registry', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final bytes = _pe(0x014c);
    final source = fixture.writeSource(bytes);
    final registry = File('${fixture.bottle.path.value}/user.reg')
      ..writeAsStringSync('registry-sentinel');

    final result = DartIoNativeDllInstaller().install(
      bottle: fixture.bottle,
      action: _action(machine: 'x86', bytes: bytes),
      resourcePath: ProgramPath(source.path),
    );

    expect(result, const NativeDllInstalled(changed: true));
    expect(
      File(
        '${fixture.bottle.path.value}/drive_c/windows/syswow64/'
        'd3dcompiler_47.dll',
      ).readAsBytesSync(),
      bytes,
    );
    expect(registry.readAsStringSync(), 'registry-sentinel');
  });

  test('rejects malformed and mismatched PE resources', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final malformed = fixture.writeSource(Uint8List.fromList([1, 2, 3]));
    expect(
      DartIoNativeDllInstaller().install(
        bottle: fixture.bottle,
        action: _action(machine: 'x86', bytes: Uint8List.fromList([1, 2, 3])),
        resourcePath: ProgramPath(malformed.path),
      ),
      isA<NativeDllInstallFailed>().having(
        (failure) => failure.code,
        'code',
        'nativeDllMachineMismatch',
      ),
    );

    final x64 = _pe(0x8664);
    final source = fixture.writeSource(x64);
    expect(
      DartIoNativeDllInstaller().install(
        bottle: fixture.bottle,
        action: _action(machine: 'x86', bytes: x64),
        resourcePath: ProgramPath(source.path),
      ),
      isA<NativeDllInstallFailed>().having(
        (failure) => failure.code,
        'code',
        'nativeDllMachineMismatch',
      ),
    );
  });

  test('rejects destination and target symlinks', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final bytes = _pe(0x014c);
    final source = fixture.writeSource(bytes);
    final destination = Directory(
      '${fixture.bottle.path.value}/drive_c/windows/syswow64',
    );
    destination.deleteSync();
    Link(destination.path).createSync(fixture.outside.path);

    expect(
      DartIoNativeDllInstaller().install(
        bottle: fixture.bottle,
        action: _action(machine: 'x86', bytes: bytes),
        resourcePath: ProgramPath(source.path),
      ),
      isA<NativeDllInstallFailed>().having(
        (failure) => failure.code,
        'code',
        'nativeDllDestinationInvalid',
      ),
    );

    Link(destination.path).deleteSync();
    destination.createSync();
    Link(
      '${destination.path}/d3dcompiler_47.dll',
    ).createSync('${fixture.outside.path}/escaped.dll');
    expect(
      DartIoNativeDllInstaller().install(
        bottle: fixture.bottle,
        action: _action(machine: 'x86', bytes: bytes),
        resourcePath: ProgramPath(source.path),
      ),
      isA<NativeDllInstallFailed>().having(
        (failure) => failure.code,
        'code',
        'nativeDllTargetSymlink',
      ),
    );
  });

  test('preserves an existing DLL when atomic replacement fails', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final bytes = _pe(0x014c);
    final source = fixture.writeSource(bytes);
    final target = File(
      '${fixture.bottle.path.value}/drive_c/windows/syswow64/'
      'd3dcompiler_47.dll',
    )..writeAsBytesSync([9, 8, 7]);

    final result =
        DartIoNativeDllInstaller(
          atomicReplace: (_, _) =>
              throw const FileSystemException('injected atomic failure'),
        ).install(
          bottle: fixture.bottle,
          action: _action(machine: 'x86', bytes: bytes),
          resourcePath: ProgramPath(source.path),
        );

    expect(result, isA<NativeDllInstallFailed>());
    expect(target.readAsBytesSync(), [9, 8, 7]);
    expect(
      target.parent.listSync().where((entity) => entity.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('rejects a changed fetched resource without mutating the target', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final expected = _pe(0x014c);
    final changed = _pe(0x014c)..[127] = 1;
    final source = fixture.writeSource(changed);
    final target = File(
      '${fixture.bottle.path.value}/drive_c/windows/syswow64/'
      'd3dcompiler_47.dll',
    )..writeAsBytesSync([9, 8, 7]);

    final result = DartIoNativeDllInstaller().install(
      bottle: fixture.bottle,
      action: _action(machine: 'x86', bytes: expected),
      resourcePath: ProgramPath(source.path),
    );

    expect(
      result,
      isA<NativeDllInstallFailed>().having(
        (failure) => failure.code,
        'code',
        'nativeDllDigestMismatch',
      ),
    );
    expect(target.readAsBytesSync(), [9, 8, 7]);
    expect(
      target.parent.listSync().where((entity) => entity.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('installs a DLL larger than the I/O chunk without whole-file reads', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final source = File('${fixture.root.path}/large-source.dll');
    final output = source.openSync(mode: FileMode.write);
    try {
      output.truncateSync(8 * 1024 * 1024);
      output.setPositionSync(0);
      output.writeFromSync([0x4d, 0x5a]);
      output.setPositionSync(0x3c);
      output.writeFromSync([0x00, 0x10, 0x00, 0x00]);
      output.setPositionSync(0x1000);
      output.writeFromSync([0x50, 0x45, 0x00, 0x00, 0x4c, 0x01]);
      output.flushSync();
    } finally {
      output.closeSync();
    }
    final action =
        PreInstallActionRecord.nativeDll(
              componentId: 'large-x86',
              machine: 'x86',
              destination: 'windowsSysWow64',
              targetFileName: 'large.dll',
              resource: NativeDllResourceRecord(
                kind: 'https',
                url: 'https://downloads.example.test/large.dll',
                sha256: sha256HexDigest(source),
                fileName: 'large.dll',
              ),
            )
            as NativeDllPreInstallAction;

    final result = DartIoNativeDllInstaller().install(
      bottle: fixture.bottle,
      action: action,
      resourcePath: ProgramPath(source.path),
    );

    expect(result, const NativeDllInstalled(changed: true));
    final target = File(
      '${fixture.bottle.path.value}/drive_c/windows/syswow64/large.dll',
    );
    expect(target.lengthSync(), source.lengthSync());
    expect(sha256HexDigest(target), action.resource.sha256.value);
  });

  test('is an idempotent no-op when the target digest already matches', () {
    final fixture = _fixture();
    addTearDown(fixture.dispose);
    final bytes = _pe(0x8664);
    final source = fixture.writeSource(bytes);
    File(
      '${fixture.bottle.path.value}/drive_c/windows/system32/'
      'd3dcompiler_47.dll',
    ).writeAsBytesSync(bytes);
    var replacements = 0;

    final result =
        DartIoNativeDllInstaller(
          atomicReplace: (_, _) => replacements += 1,
        ).install(
          bottle: fixture.bottle,
          action: _action(machine: 'x64', bytes: bytes),
          resourcePath: ProgramPath(source.path),
        );

    expect(result, const NativeDllInstalled(changed: false));
    expect(replacements, 0);
  });

  test('rejects machine and destination mismatch in the domain model', () {
    final bytes = _pe(0x014c);
    expect(
      () => PreInstallActionRecord.nativeDll(
        componentId: 'd3dcompiler_47-x86',
        machine: 'x86',
        destination: 'windowsSystem32',
        targetFileName: 'd3dcompiler_47.dll',
        resource: _resource(bytes, 'd3dcompiler_47_32.dll'),
      ),
      throwsArgumentError,
    );
    expect(
      () => NativeDllFileName('../d3dcompiler_47.dll'),
      throwsArgumentError,
    );
  });

  test('rejects duplicate native DLL destination and target pairs', () {
    final bytes = _pe(0x014c);
    final action = _action(machine: 'x86', bytes: bytes);
    expect(
      () => InstallProfileRecord(
        id: 'duplicate-native-target',
        sourceId: 'duplicate-native-target.json',
        manifestDigest: 'a' * 64,
        name: 'Duplicate',
        profileVersion: 1,
        summary: 'Duplicate native DLL target.',
        platforms: const ['macos'],
        windowsVersion: 'win10',
        managedProgramPath: r'C:\Duplicate\Duplicate.exe',
        installerResource: InstallerResourceRecord(
          kind: 'https',
          url: 'https://downloads.example.test/Setup.exe',
          sha256: 'b' * 64,
          fileName: 'Setup.exe',
        ),
        preInstallActions: [action, action],
        compatibilityProfile: CompatibilityProfileRecord(
          id: 'duplicate-native-target',
          profileVersion: 1,
          childProcessRules: const [],
        ),
      ),
      throwsArgumentError,
    );
  });
}

NativeDllPreInstallAction _action({
  required String machine,
  required Uint8List bytes,
}) {
  return PreInstallActionRecord.nativeDll(
        componentId: 'd3dcompiler_47-$machine',
        machine: machine,
        destination: machine == 'x86' ? 'windowsSysWow64' : 'windowsSystem32',
        targetFileName: 'd3dcompiler_47.dll',
        resource: _resource(
          bytes,
          machine == 'x86' ? 'd3dcompiler_47_32.dll' : 'd3dcompiler_47.dll',
        ),
      )
      as NativeDllPreInstallAction;
}

NativeDllResourceRecord _resource(Uint8List bytes, String fileName) {
  return NativeDllResourceRecord(
    kind: 'https',
    url: 'https://downloads.example.test/$fileName',
    sha256: sha256.convert(bytes).toString(),
    fileName: fileName,
  );
}

Uint8List _pe(int machine) {
  final bytes = Uint8List(128);
  final data = ByteData.sublistView(bytes);
  bytes[0] = 0x4d;
  bytes[1] = 0x5a;
  data.setUint32(0x3c, 0x40, Endian.little);
  bytes[0x40] = 0x50;
  bytes[0x41] = 0x45;
  data.setUint16(0x44, machine, Endian.little);
  return bytes;
}

_NativeDllFixture _fixture() {
  final root = Directory.systemTemp.createTempSync('konyak-native-dll-test-');
  final bottleDirectory = Directory('${root.path}/bottle');
  Directory(
    '${bottleDirectory.path}/drive_c/windows/syswow64',
  ).createSync(recursive: true);
  Directory(
    '${bottleDirectory.path}/drive_c/windows/system32',
  ).createSync(recursive: true);
  final outside = Directory('${root.path}/outside')..createSync();
  return _NativeDllFixture(
    root: root,
    outside: outside,
    bottle: BottleRecord(
      id: 'test',
      name: 'Test',
      path: bottleDirectory.path,
      windowsVersion: 'win10',
    ),
  );
}

final class _NativeDllFixture {
  const _NativeDllFixture({
    required this.root,
    required this.outside,
    required this.bottle,
  });

  final Directory root;
  final Directory outside;
  final BottleRecord bottle;

  File writeSource(Uint8List bytes) =>
      File('${root.path}/source.dll')..writeAsBytesSync(bytes);

  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
