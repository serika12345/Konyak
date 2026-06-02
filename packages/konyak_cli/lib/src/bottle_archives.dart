part of '../konyak_cli.dart';

BottleArchiveExportResult _exportBottleArchive({
  required BottleRecord bottle,
  required String archivePath,
}) {
  final normalizedBottlePath = _normalizeFilesystemPath(bottle.path);
  final bottleDirectory = Directory(normalizedBottlePath);
  if (!bottleDirectory.existsSync()) {
    return BottleArchiveExportFailed('Bottle directory was not found.');
  }

  try {
    final normalizedArchivePath = _normalizeFilesystemPath(archivePath);
    if (normalizedArchivePath == normalizedBottlePath ||
        normalizedArchivePath.startsWith('$normalizedBottlePath/')) {
      return BottleArchiveExportFailed(
        'Bottle archive path must be outside the bottle directory.',
      );
    }

    final archive = File(archivePath);
    archive.parent.createSync(recursive: true);
    final result = Process.runSync('tar', [
      '-cf',
      archive.path,
      '-C',
      _dirname(normalizedBottlePath),
      _basename(normalizedBottlePath),
    ], runInShell: false);
    if (result.exitCode != 0) {
      return BottleArchiveExportFailed(
        _commandFailureMessage('export bottle archive', result),
      );
    }
  } on FileSystemException catch (error) {
    return BottleArchiveExportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveExportFailed(error.message);
  }

  return BottleArchiveExported(
    BottleArchiveRecord(bottleId: bottle.id, archivePath: archivePath),
  );
}

BottleArchiveImportResult _importBottleArchive({
  required String archivePath,
  required String bottleDirectory,
  required bool Function(String bottleId) hasBottle,
  void Function(BottleRecord bottle)? onImported,
}) {
  final archive = File(archivePath);
  if (!archive.existsSync()) {
    return BottleArchiveImportFailed('Bottle archive was not found.');
  }

  final listing = _validatedBottleArchiveListing(archivePath);
  switch (listing) {
    case _InvalidBottleArchiveListing(:final message):
      return BottleArchiveImportFailed(message);
    case _ValidBottleArchiveListing():
      break;
  }

  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-bottle-import-',
  );
  try {
    final extraction = Process.runSync('tar', [
      '-xf',
      archivePath,
      '-C',
      tempDirectory.path,
    ], runInShell: false);
    if (extraction.exitCode != 0) {
      return BottleArchiveImportFailed(
        _commandFailureMessage('import bottle archive', extraction),
      );
    }

    final extractedBottlePath = _joinPath(tempDirectory.path, [
      listing.topLevelDirectory,
    ]);
    final extractedBottleDirectory = Directory(extractedBottlePath);
    if (!extractedBottleDirectory.existsSync()) {
      return const BottleArchiveImportFailed(
        'Bottle archive does not contain a bottle directory.',
      );
    }

    final imported = _readBottleMetadata(extractedBottlePath);
    if (!_isValidBottleArchiveId(imported.id)) {
      return const BottleArchiveImportFailed(
        'Bottle archive metadata contains an invalid bottle id.',
      );
    }
    if (hasBottle(imported.id)) {
      return BottleArchiveImportConflict(imported.id);
    }

    final destinationPath = _joinPath(bottleDirectory, [imported.id]);
    if (Directory(destinationPath).existsSync()) {
      return BottleArchiveImportConflict(imported.id);
    }

    final relocated = imported.copyWith(path: destinationPath);
    _moveDirectory(from: extractedBottlePath, to: destinationPath);
    _writeBottleMetadata(relocated);
    onImported?.call(relocated);

    return BottleArchiveImported(relocated);
  } on FileSystemException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on FormatException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

sealed class _BottleArchiveListing {
  const _BottleArchiveListing();
}

final class _ValidBottleArchiveListing extends _BottleArchiveListing {
  const _ValidBottleArchiveListing({required this.topLevelDirectory});

  final String topLevelDirectory;
}

final class _InvalidBottleArchiveListing extends _BottleArchiveListing {
  const _InvalidBottleArchiveListing(this.message);

  final String message;
}

_BottleArchiveListing _validatedBottleArchiveListing(String archivePath) {
  final result = Process.runSync('tar', [
    '-tf',
    archivePath,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _InvalidBottleArchiveListing(
      _commandFailureMessage('inspect bottle archive', result),
    );
  }

  final entries = _processOutputToString(result.stdout)
      .split('\n')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
  if (entries.isEmpty) {
    return const _InvalidBottleArchiveListing('Bottle archive is empty.');
  }

  final topLevelDirectories = <String>{};
  var hasMetadata = false;
  for (final entry in entries) {
    if (!_isSafeArchiveEntryPath(entry)) {
      return const _InvalidBottleArchiveListing(
        'Bottle archive contains an unsafe path.',
      );
    }

    final segments = entry
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    topLevelDirectories.add(segments.first);
    if (segments.length == 2 && segments.last == 'metadata.json') {
      hasMetadata = true;
    }
  }

  if (topLevelDirectories.length != 1) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive must contain exactly one bottle directory.',
    );
  }
  if (!hasMetadata) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive does not contain bottle metadata.',
    );
  }

  return _ValidBottleArchiveListing(
    topLevelDirectory: topLevelDirectories.single,
  );
}

bool _isSafeArchiveEntryPath(String path) {
  if (path.startsWith('/') ||
      path.startsWith(r'\') ||
      path.contains('\u0000')) {
    return false;
  }
  if (path.contains(r'\')) {
    return false;
  }

  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  var hasSegment = false;
  for (final segment in segments) {
    hasSegment = true;
    if (segment == '.' || segment == '..') {
      return false;
    }
  }

  return hasSegment;
}

bool _isValidBottleArchiveId(String id) {
  return id.isNotEmpty &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      id != '.' &&
      id != '..';
}
