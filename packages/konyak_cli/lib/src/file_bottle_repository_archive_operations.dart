part of '../konyak_cli.dart';

class _FileBottleRepositoryArchiveOperations {
  const _FileBottleRepositoryArchiveOperations({
    required this.bottleDirectory,
    required BottleRecord? Function(String id) findBottle,
  }) : _findBottle = findBottle;

  final String bottleDirectory;
  final BottleRecord? Function(String id) _findBottle;

  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: bottleDirectory,
      hasBottle: (bottleId) => _findBottle(bottleId) != null,
    );
  }
}
