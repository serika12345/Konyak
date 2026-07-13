import 'dart:io';

import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/managed_profile_program_verifier_io.dart';
import 'package:test/test.dart';

void main() {
  test('resolves a managed C-drive executable inside the bottle', () {
    final root = Directory.systemTemp.createTempSync(
      'konyak-managed-program-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final executable = File('${root.path}/drive_c/Program Files/Test/Test.exe')
      ..createSync(recursive: true);
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: root.path,
      windowsVersion: 'win10',
    );

    final result = const DartIoManagedProfileProgramVerifier().verify(
      bottle: bottle,
      managedProgramPath: ProgramPath(r'C:\Program Files\Test\Test.exe'),
    );

    expect(result, isA<ManagedProfileProgramVerified>());
    expect(
      (result as ManagedProfileProgramVerified).path.value,
      executable.resolveSymbolicLinksSync(),
    );
  });

  test('rejects a managed executable symlink that escapes drive_c', () {
    final root = Directory.systemTemp.createTempSync(
      'konyak-managed-program-symlink-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final outside = File('${root.path}/outside.exe')
      ..createSync(recursive: true);
    final link = Link('${root.path}/drive_c/Test/Test.exe');
    link.createSync(outside.path, recursive: true);
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: root.path,
      windowsVersion: 'win10',
    );

    final result = const DartIoManagedProfileProgramVerifier().verify(
      bottle: bottle,
      managedProgramPath: ProgramPath(r'C:\Test\Test.exe'),
    );

    expect(result, isA<ManagedProfileProgramVerificationFailed>());
    expect(
      (result as ManagedProfileProgramVerificationFailed).code,
      'managedProgramOutsideBottle',
    );
  });

  test('rejects a drive_c root symlink that escapes the bottle', () {
    final root = Directory.systemTemp.createTempSync(
      'konyak-managed-drive-symlink-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final outside = Directory('${root.path}/outside')..createSync();
    File('${outside.path}/Test.exe').createSync();
    final bottleRoot = Directory('${root.path}/bottle')..createSync();
    Link('${bottleRoot.path}/drive_c').createSync(outside.path);
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: bottleRoot.path,
      windowsVersion: 'win10',
    );

    final result = const DartIoManagedProfileProgramVerifier().verify(
      bottle: bottle,
      managedProgramPath: ProgramPath(r'C:\Test.exe'),
    );

    expect(result, isA<ManagedProfileProgramVerificationFailed>());
    expect(
      (result as ManagedProfileProgramVerificationFailed).code,
      'managedProgramOutsideBottle',
    );
  });

  test('rejects a missing managed executable', () {
    final root = Directory.systemTemp.createTempSync(
      'konyak-managed-program-missing-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/drive_c').createSync(recursive: true);
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: root.path,
      windowsVersion: 'win10',
    );

    final result = const DartIoManagedProfileProgramVerifier().verify(
      bottle: bottle,
      managedProgramPath: ProgramPath(r'C:\Test\Missing.exe'),
    );

    expect(result, isA<ManagedProfileProgramVerificationFailed>());
    expect(
      (result as ManagedProfileProgramVerificationFailed).code,
      'managedProgramMissing',
    );
  });
}
