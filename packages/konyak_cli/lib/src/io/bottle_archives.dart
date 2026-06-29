import 'dart:io';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'external_payload_helpers.dart';
import 'io_result.dart';
import 'repository_storage_io.dart';

BottleArchiveExportResult writeBottleArchive({
  required BottleRecord bottle,
  required String archivePath,
}) {
  final normalizedBottlePath = normalizeFilesystemPath(bottle.path.value);
  final bottleDirectory = Directory(normalizedBottlePath);
  if (!bottleDirectory.existsSync()) {
    return BottleArchiveExportFailed('Bottle directory was not found.');
  }

  try {
    final normalizedArchivePath = normalizeFilesystemPath(archivePath);
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
      dirname(normalizedBottlePath),
      basename(normalizedBottlePath),
    ], runInShell: false);
    if (result.exitCode != 0) {
      return BottleArchiveExportFailed(
        commandFailureMessage('export bottle archive', result),
      );
    }
  } on FileSystemException catch (error) {
    return BottleArchiveExportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveExportFailed(error.message);
  }

  return BottleArchiveExported(
    BottleArchiveRecord(bottleId: bottle.id.value, archivePath: archivePath),
  );
}

BottleArchiveImportResult readBottleArchive({
  required String archivePath,
  required String bottleDirectory,
  required IoResult<bool> Function(String bottleId) hasBottle,
  void Function(BottleRecord bottle)? onImported,
}) {
  final archive = File(archivePath);
  if (!archive.existsSync()) {
    return BottleArchiveImportFailed('Bottle archive was not found.');
  }

  final listing = validatedBottleArchiveListing(archivePath);
  switch (listing) {
    case InvalidBottleArchiveListing(:final message):
      return BottleArchiveImportFailed(message);
    case ValidBottleArchiveListing():
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
        commandFailureMessage('import bottle archive', extraction),
      );
    }

    final extractedBottlePath = joinPath(tempDirectory.path, [
      listing.topLevelDirectory,
    ]);
    final extractedBottleDirectory = Directory(extractedBottlePath);
    if (!extractedBottleDirectory.existsSync()) {
      return const BottleArchiveImportFailed(
        'Bottle archive does not contain a bottle directory.',
      );
    }

    final imported = readBottleMetadata(extractedBottlePath);
    if (!isValidBottleArchiveId(imported.id.value)) {
      return const BottleArchiveImportFailed(
        'Bottle archive metadata contains an invalid bottle id.',
      );
    }
    return hasBottle(imported.id.value).fold(BottleArchiveImportFailed.new, (
      exists,
    ) {
      if (exists) {
        return BottleArchiveImportConflict(imported.id.value);
      }

      final destinationPath = joinPath(bottleDirectory, [imported.id.value]);
      if (Directory(destinationPath).existsSync()) {
        return BottleArchiveImportConflict(imported.id.value);
      }

      final relocated = imported.withPath(BottlePath(destinationPath));
      moveDirectory(from: extractedBottlePath, to: destinationPath);
      writeBottleMetadata(relocated);
      onImported?.call(relocated);

      return BottleArchiveImported(relocated);
    });
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

sealed class BottleArchiveListing {
  const BottleArchiveListing();
}

final class ValidBottleArchiveListing extends BottleArchiveListing {
  const ValidBottleArchiveListing({required this.topLevelDirectory});

  final String topLevelDirectory;
}

final class InvalidBottleArchiveListing extends BottleArchiveListing {
  const InvalidBottleArchiveListing(this.message);

  final String message;
}

BottleArchiveListing validatedBottleArchiveListing(String archivePath) {
  final result = Process.runSync('tar', [
    '-tf',
    archivePath,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return InvalidBottleArchiveListing(
      commandFailureMessage('inspect bottle archive', result),
    );
  }

  final entries = processOutputToString(result.stdout)
      .split('\n')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
  if (entries.isEmpty) {
    return const InvalidBottleArchiveListing('Bottle archive is empty.');
  }

  final topLevelDirectories = <String>{};
  var hasMetadata = false;
  for (final entry in entries) {
    if (!isSafeArchiveEntryPath(entry)) {
      return const InvalidBottleArchiveListing(
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
    return const InvalidBottleArchiveListing(
      'Bottle archive must contain exactly one bottle directory.',
    );
  }
  if (!hasMetadata) {
    return const InvalidBottleArchiveListing(
      'Bottle archive does not contain bottle metadata.',
    );
  }

  return ValidBottleArchiveListing(
    topLevelDirectory: topLevelDirectories.single,
  );
}

bool isSafeArchiveEntryPath(String path) {
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

bool isValidBottleArchiveId(String id) {
  return id.isNotEmpty &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      id != '.' &&
      id != '..';
}
