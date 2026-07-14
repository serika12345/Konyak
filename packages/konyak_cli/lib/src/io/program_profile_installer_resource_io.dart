import 'dart:io';

import '../domain/program/program_profile_install_models.dart';
import '../domain/shared/domain_helpers.dart';
import '../domain/shared/domain_value_objects.dart';
import 'file_digest_io.dart';

const konyakProfileInstallerMaxRedirects = 5;
const konyakProfileInstallerConnectTimeoutSeconds = 30;
const konyakProfileInstallerTotalTimeoutSeconds = 1800;
const konyakProfileInstallerMaxBytes = 4 * 1024 * 1024 * 1024;

abstract interface class ProfileInstallerProcessRunner {
  ProcessResult run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  });
}

final class DartIoProfileInstallerProcessRunner
    implements ProfileInstallerProcessRunner {
  const DartIoProfileInstallerProcessRunner();

  @override
  ProcessResult run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  }) {
    return Process.runSync(executable, arguments, runInShell: runInShell);
  }
}

final class DartIoProfileInstallerResourceFetcher
    implements ProfileInstallerResourceFetcher {
  DartIoProfileInstallerResourceFetcher({
    required this.cacheRoot,
    this.processRunner = const DartIoProfileInstallerProcessRunner(),
    this.maxBytes = konyakProfileInstallerMaxBytes,
  });

  final String cacheRoot;
  final ProfileInstallerProcessRunner processRunner;
  final int maxBytes;
  final Map<String, _OwnedInstallerResource> _ownedResources =
      <String, _OwnedInstallerResource>{};

  @override
  ProfileInstallerResourceFetchResult fetch(
    ProfileResourceFetchRequest resource,
  ) {
    final cacheDirectory = Directory(cacheRoot);
    Directory? stagingDirectory;

    try {
      cacheDirectory.createSync(recursive: true);
      final cacheRealPath = cacheDirectory.resolveSymbolicLinksSync();
      if (FileStat.statSync(cacheRealPath).type !=
          FileSystemEntityType.directory) {
        throw FileSystemException(
          'Profile installer cache root is not a directory.',
          cacheRoot,
        );
      }

      stagingDirectory = cacheDirectory.createTempSync(
        'profile-installer-resource-',
      );
      final stagingRealPath = _ownedDirectoryRealPath(
        directory: stagingDirectory,
        rootRealPath: cacheRealPath,
      );
      final destination = File(
        domainJoinPath(stagingDirectory.path, <String>[resource.fileName]),
      );
      final partial = File('${destination.path}.part');

      // Dart cannot keep an O_NOFOLLOW file descriptor open across a separate
      // curl process. An exclusive, private staging directory avoids consuming
      // attacker-controlled pre-existing paths, and the post-process check
      // detects link replacement before Konyak consumes the payload. This does
      // not prevent a same-UID process from racing curl into writing through a
      // replaced link; such a process can already modify the same user's files.
      partial.createSync(exclusive: true);
      _regularFileRealPath(file: partial, rootRealPath: stagingRealPath);
      if (_entityExistsWithoutFollowingLinks(destination.path)) {
        throw FileSystemException(
          'Profile installer destination already exists.',
          destination.path,
        );
      }

      final result = processRunner.run('curl', <String>[
        '--fail',
        '--location',
        '--silent',
        '--show-error',
        '--max-redirs',
        '$konyakProfileInstallerMaxRedirects',
        '--connect-timeout',
        '$konyakProfileInstallerConnectTimeoutSeconds',
        '--max-time',
        '$konyakProfileInstallerTotalTimeoutSeconds',
        '--max-filesize',
        '$maxBytes',
        '--proto',
        '=https',
        '--proto-redir',
        '=https',
        '--output',
        partial.path,
        '--',
        resource.url.value,
      ], runInShell: false);
      if (result.exitCode != 0) {
        _deleteOwnedStagingDirectory(
          directory: stagingDirectory,
          rootRealPath: cacheRealPath,
        );
        return ProfileInstallerResourceDownloadFailed(
          'Installer resource download failed with exit code '
          '${result.exitCode}.',
        );
      }

      _regularFileRealPath(file: partial, rootRealPath: stagingRealPath);
      if (partial.lengthSync() > maxBytes) {
        _deleteOwnedStagingDirectory(
          directory: stagingDirectory,
          rootRealPath: cacheRealPath,
        );
        return ProfileInstallerResourceDownloadFailed(
          'Installer resource exceeds the $maxBytes byte limit.',
        );
      }

      final actualDigest = sha256HexDigest(partial);
      if (actualDigest.toLowerCase() != resource.sha256.value.toLowerCase()) {
        _deleteOwnedStagingDirectory(
          directory: stagingDirectory,
          rootRealPath: cacheRealPath,
        );
        return ProfileInstallerResourceDigestMismatch(
          expected: resource.sha256,
          actual: actualDigest,
        );
      }

      if (_entityExistsWithoutFollowingLinks(destination.path)) {
        throw FileSystemException(
          'Profile installer destination appeared during download.',
          destination.path,
        );
      }
      partial.renameSync(destination.path);
      final destinationRealPath = _regularFileRealPath(
        file: destination,
        rootRealPath: stagingRealPath,
      );
      _ownedResources[destinationRealPath] = _OwnedInstallerResource(
        cacheRealPath: cacheRealPath,
        stagingPath: stagingDirectory.path,
        stagingRealPath: stagingRealPath,
      );
      return ProfileInstallerResourceFetched(ProgramPath(destinationRealPath));
    } on FileSystemException catch (error) {
      _deleteOwnedStagingDirectoryIfCreated(
        directory: stagingDirectory,
        cacheDirectory: cacheDirectory,
      );
      return ProfileInstallerResourceDownloadFailed(error.message);
    } on ProcessException catch (error) {
      _deleteOwnedStagingDirectoryIfCreated(
        directory: stagingDirectory,
        cacheDirectory: cacheDirectory,
      );
      return ProfileInstallerResourceDownloadFailed(error.message);
    }
  }

  @override
  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  ) {
    final resourcePath = resource.path.value;
    final ownership = _ownedResources.remove(resourcePath);
    if (ownership == null) {
      return const ProfileInstallerResourceReleaseFailed(
        code: 'installerResourceReleaseNotOwned',
        message: 'Installer resource is not owned by this fetcher.',
      );
    }

    final stagingDirectory = Directory(ownership.stagingPath);
    try {
      final currentCacheRealPath = Directory(
        cacheRoot,
      ).resolveSymbolicLinksSync();
      if (currentCacheRealPath != ownership.cacheRealPath) {
        return const ProfileInstallerResourceReleaseFailed(
          code: 'installerResourceReleaseRootChanged',
          message: 'Installer resource cache root changed before cleanup.',
        );
      }
      if (FileSystemEntity.typeSync(
            stagingDirectory.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.directory) {
        _deleteOwnedStagingDirectory(
          directory: stagingDirectory,
          rootRealPath: ownership.cacheRealPath,
        );
        return const ProfileInstallerResourceReleaseFailed(
          code: 'installerResourceReleaseStagingChanged',
          message:
              'Installer resource staging directory changed before cleanup.',
        );
      }
      final currentStagingRealPath = stagingDirectory
          .resolveSymbolicLinksSync();
      if (currentStagingRealPath != ownership.stagingRealPath ||
          !isPathWithinRoot(
            path: currentStagingRealPath,
            root: ownership.cacheRealPath,
          )) {
        return const ProfileInstallerResourceReleaseFailed(
          code: 'installerResourceReleaseStagingChanged',
          message:
              'Installer resource staging directory escaped before cleanup.',
        );
      }
      final currentResourceRealPath = _regularFileRealPath(
        file: File(resourcePath),
        rootRealPath: ownership.stagingRealPath,
      );
      if (currentResourceRealPath != resourcePath) {
        return const ProfileInstallerResourceReleaseFailed(
          code: 'installerResourceReleaseResourceChanged',
          message: 'Installer resource changed before cleanup.',
        );
      }

      _deleteOwnedStagingDirectory(
        directory: stagingDirectory,
        rootRealPath: ownership.cacheRealPath,
      );
      return const ProfileInstallerResourceReleased();
    } on FileSystemException catch (error) {
      return ProfileInstallerResourceReleaseFailed(
        code: 'installerResourceReleaseFailed',
        message: error.message,
      );
    }
  }
}

final class _OwnedInstallerResource {
  const _OwnedInstallerResource({
    required this.cacheRealPath,
    required this.stagingPath,
    required this.stagingRealPath,
  });

  final String cacheRealPath;
  final String stagingPath;
  final String stagingRealPath;
}

String _ownedDirectoryRealPath({
  required Directory directory,
  required String rootRealPath,
}) {
  if (FileSystemEntity.typeSync(directory.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw FileSystemException(
      'Profile installer staging path is not a directory.',
      directory.path,
    );
  }
  final realPath = directory.resolveSymbolicLinksSync();
  if (realPath == rootRealPath ||
      !isPathWithinRoot(path: realPath, root: rootRealPath)) {
    throw FileSystemException(
      'Profile installer staging directory escaped the cache root.',
      directory.path,
    );
  }
  return realPath;
}

String _regularFileRealPath({
  required File file,
  required String rootRealPath,
}) {
  if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw FileSystemException(
      'Profile installer resource is not a regular file.',
      file.path,
    );
  }
  final realPath = file.resolveSymbolicLinksSync();
  if (!isPathWithinRoot(path: realPath, root: rootRealPath) ||
      FileStat.statSync(realPath).type != FileSystemEntityType.file) {
    throw FileSystemException(
      'Profile installer resource escaped its staging directory.',
      file.path,
    );
  }
  return realPath;
}

bool _entityExistsWithoutFollowingLinks(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.notFound;
}

void _deleteOwnedStagingDirectoryIfCreated({
  required Directory? directory,
  required Directory cacheDirectory,
}) {
  if (directory == null) {
    return;
  }
  try {
    _deleteOwnedStagingDirectory(
      directory: directory,
      rootRealPath: cacheDirectory.resolveSymbolicLinksSync(),
    );
  } on FileSystemException {
    // Cleanup must not replace the original fetch failure or cross the cache
    // root when the path changed after creation.
  }
}

void _deleteOwnedStagingDirectory({
  required Directory directory,
  required String rootRealPath,
}) {
  final type = FileSystemEntity.typeSync(directory.path, followLinks: false);
  if (type == FileSystemEntityType.notFound) {
    return;
  }
  if (type == FileSystemEntityType.link) {
    Link(directory.path).deleteSync();
    return;
  }
  if (type != FileSystemEntityType.directory) {
    throw FileSystemException(
      'Profile installer staging path changed type during cleanup.',
      directory.path,
    );
  }
  final realPath = directory.resolveSymbolicLinksSync();
  if (realPath != rootRealPath &&
      isPathWithinRoot(path: realPath, root: rootRealPath)) {
    directory.deleteSync(recursive: true);
  }
}
