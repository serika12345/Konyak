import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/io/program_profile_installer_resource_io.dart';
import 'package:test/test.dart';

void main() {
  test('fetches through HTTPS-only curl into .part before digest success', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-cache-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    final payload = <int>[1, 2, 3, 4];
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: payload,
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
    );
    final resource = InstallerResourceRecord(
      kind: 'https',
      url: 'https://downloads.example.test/Setup.exe',
      sha256: sha256.convert(payload).toString(),
      fileName: 'Setup.exe',
    );

    final result = _fetchInstaller(fetcher, resource);

    expect(result, isA<ProfileInstallerResourceFetched>());
    final fetched = result as ProfileInstallerResourceFetched;
    expect(File(fetched.path.value).readAsBytesSync(), payload);
    expect(processRunner.executable, 'curl');
    expect(processRunner.runInShell, isFalse);
    expect(
      processRunner.arguments,
      containsAllInOrder(<String>[
        '--max-redirs',
        '$konyakProfileInstallerMaxRedirects',
        '--connect-timeout',
        '$konyakProfileInstallerConnectTimeoutSeconds',
        '--max-time',
        '$konyakProfileInstallerTotalTimeoutSeconds',
        '--max-filesize',
        '$konyakProfileInstallerMaxBytes',
        '--proto',
        '=https',
        '--proto-redir',
        '=https',
        '--output',
      ]),
    );
    expect(processRunner.outputPath, endsWith('Setup.exe.part'));
    expect(
      processRunner.arguments.sublist(processRunner.arguments.length - 2),
      <String>['--', resource.url.value],
    );
    expect(processRunner.arguments.last, resource.url.value);
    final cacheRootRealPath = cacheRoot.resolveSymbolicLinksSync();
    final fetchedRealPath = File(fetched.path.value).resolveSymbolicLinksSync();
    expect(
      fetchedRealPath,
      startsWith('$cacheRootRealPath${Platform.pathSeparator}'),
    );
    expect(File('${fetched.path.value}.part').existsSync(), isFalse);
    expect(fetcher.release(fetched), isA<ProfileInstallerResourceReleased>());
    expect(File(fetched.path.value).existsSync(), isFalse);
  });

  test('does not reuse a digest directory symlink or overwrite its target', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-symlink-cache-test-',
    );
    final outside = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-symlink-outside-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));
    final payload = <int>[1, 2, 3, 4];
    final digest = sha256.convert(payload).toString();
    final outsideInstaller = File('${outside.path}/Setup.exe')
      ..writeAsStringSync('sentinel');
    final digestLink = Link('${cacheRoot.path}/$digest')
      ..createSync(outside.path);
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: payload,
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
    );

    final result = _fetchInstaller(
      fetcher,
      InstallerResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/Setup.exe',
        sha256: digest,
        fileName: 'Setup.exe',
      ),
    );

    expect(result, isA<ProfileInstallerResourceFetched>());
    expect(outsideInstaller.readAsStringSync(), 'sentinel');
    expect(
      FileSystemEntity.typeSync(digestLink.path, followLinks: false),
      FileSystemEntityType.link,
    );
    final fetched = result as ProfileInstallerResourceFetched;
    final cacheRootRealPath = cacheRoot.resolveSymbolicLinksSync();
    expect(
      File(fetched.path.value).resolveSymbolicLinksSync(),
      startsWith('$cacheRootRealPath${Platform.pathSeparator}'),
    );
    expect(fetcher.release(fetched), isA<ProfileInstallerResourceReleased>());
  });

  test('release rejects an unowned path without deleting outside data', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-release-cache-test-',
    );
    final outside = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-release-outside-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));
    final outsideFile = File('${outside.path}/Setup.exe')
      ..writeAsStringSync('sentinel');
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: RecordingProfileInstallerProcessRunner(
        payload: const <int>[1, 2, 3, 4],
      ),
    );

    final result = fetcher.release(
      ProfileInstallerResourceFetched(ProgramPath(outsideFile.path)),
    );

    expect(result, isA<ProfileInstallerResourceReleaseFailed>());
    expect(
      (result as ProfileInstallerResourceReleaseFailed).code,
      'installerResourceReleaseNotOwned',
    );
    expect(outsideFile.readAsStringSync(), 'sentinel');
  });

  test('detects a partial symlink replacement after curl returns', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-part-link-cache-test-',
    );
    final outside = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-part-link-outside-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));
    final payload = <int>[1, 2, 3, 4];
    final outsideFile = File('${outside.path}/outside.exe')
      ..writeAsBytesSync(payload);
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: payload,
      partialLinkTarget: outsideFile.path,
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
    );

    final result = _fetchInstaller(
      fetcher,
      InstallerResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/Setup.exe',
        sha256: sha256.convert(payload).toString(),
        fileName: 'Setup.exe',
      ),
    );

    expect(result, isA<ProfileInstallerResourceDownloadFailed>());
    expect(outsideFile.readAsBytesSync(), payload);
  });

  test('rejects a staged destination symlink escape', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-final-link-cache-test-',
    );
    final outside = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-final-link-outside-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    addTearDown(() => outside.deleteSync(recursive: true));
    final payload = <int>[1, 2, 3, 4];
    final outsideFile = File('${outside.path}/outside.exe')
      ..writeAsStringSync('sentinel');
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: payload,
      destinationLinkTarget: outsideFile.path,
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
    );

    final result = _fetchInstaller(
      fetcher,
      InstallerResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/Setup.exe',
        sha256: sha256.convert(payload).toString(),
        fileName: 'Setup.exe',
      ),
    );

    expect(result, isA<ProfileInstallerResourceDownloadFailed>());
    expect(outsideFile.readAsStringSync(), 'sentinel');
  });

  test('removes partial payload when the digest does not match', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-digest-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: const <int>[1, 2, 3, 4],
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
    );

    final result = _fetchInstaller(
      fetcher,
      InstallerResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/Setup.exe',
        sha256: '0123456789abcdef' * 4,
        fileName: 'Setup.exe',
      ),
    );

    expect(result, isA<ProfileInstallerResourceDigestMismatch>());
    expect(File(processRunner.outputPath).existsSync(), isFalse);
    expect(
      File(
        processRunner.outputPath.replaceFirst(RegExp(r'\.part$'), ''),
      ).existsSync(),
      isFalse,
    );
  });

  test('enforces the configured download size limit and cleans staging', () {
    final cacheRoot = Directory.systemTemp.createTempSync(
      'konyak-profile-resource-size-test-',
    );
    addTearDown(() => cacheRoot.deleteSync(recursive: true));
    final processRunner = RecordingProfileInstallerProcessRunner(
      payload: const <int>[1, 2, 3, 4],
    );
    final fetcher = DartIoProfileInstallerResourceFetcher(
      cacheRoot: cacheRoot.path,
      processRunner: processRunner,
      maxBytes: 3,
    );

    final result = _fetchInstaller(
      fetcher,
      InstallerResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/Setup.exe',
        sha256: sha256.convert(const <int>[1, 2, 3, 4]).toString(),
        fileName: 'Setup.exe',
      ),
    );

    expect(result, isA<ProfileInstallerResourceDownloadFailed>());
    expect(
      processRunner.arguments,
      containsAllInOrder(const <String>['--max-filesize', '3']),
    );
    expect(File(processRunner.outputPath).existsSync(), isFalse);
  });
}

ProfileInstallerResourceFetchResult _fetchInstaller(
  DartIoProfileInstallerResourceFetcher fetcher,
  InstallerResourceRecord resource,
) {
  return fetcher.fetch(ProfileResourceFetchRequest.installer(resource));
}

final class RecordingProfileInstallerProcessRunner
    implements ProfileInstallerProcessRunner {
  RecordingProfileInstallerProcessRunner({
    required this.payload,
    this.partialLinkTarget = '',
    this.destinationLinkTarget = '',
  });

  final List<int> payload;
  final String partialLinkTarget;
  final String destinationLinkTarget;
  String executable = '';
  List<String> arguments = const <String>[];
  bool runInShell = true;

  String get outputPath {
    final outputIndex = arguments.indexOf('--output');
    return arguments[outputIndex + 1];
  }

  @override
  ProcessResult run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  }) {
    this.executable = executable;
    this.arguments = List<String>.unmodifiable(arguments);
    this.runInShell = runInShell;
    if (partialLinkTarget.isNotEmpty) {
      final output = File(outputPath);
      if (output.existsSync()) {
        output.deleteSync();
      }
      Link(outputPath).createSync(partialLinkTarget);
    } else {
      File(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(payload);
    }
    if (destinationLinkTarget.isNotEmpty) {
      Link(
        outputPath.replaceFirst(RegExp(r'\.part$'), ''),
      ).createSync(destinationLinkTarget);
    }
    return ProcessResult(1, 0, '', '');
  }
}
