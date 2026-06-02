part of '../konyak_cli.dart';

class _FileBottleRepositoryArchiveOperations {
  const _FileBottleRepositoryArchiveOperations({
    required this.bottleDirectory,
    required IoResult<Option<BottleRecord>> Function(String id) findBottle,
  }) : _findBottle = findBottle;

  final String bottleDirectory;
  final IoResult<Option<BottleRecord>> Function(String id) _findBottle;

  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return _findBottle(request.bottleId).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId),
        (bottle) => _exportBottleArchive(
          bottle: bottle,
          archivePath: request.archivePath,
        ),
      ),
    );
  }

  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: bottleDirectory,
      hasBottle: (bottleId) => _findBottle(
        bottleId,
      ).getOrElse((_) => const Option<BottleRecord>.none()).isSome(),
    );
  }
}
