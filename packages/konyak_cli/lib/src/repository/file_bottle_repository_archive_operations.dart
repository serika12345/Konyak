import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/bottle_archives.dart';
import '../io/io_result.dart';

class FileBottleRepositoryArchiveOperations {
  const FileBottleRepositoryArchiveOperations({
    required this.bottleDirectory,
    required this.findBottle,
  });

  final String bottleDirectory;
  final IoResult<Option<BottleRecord>> Function(BottleId id) findBottle;

  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return findBottle(request.bottleId).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId.value),
        (bottle) => writeBottleArchive(
          bottle: bottle,
          archivePath: request.archivePath.value,
        ),
      ),
    );
  }

  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return readBottleArchive(
      archivePath: request.archivePath.value,
      bottleDirectory: bottleDirectory,
      hasBottle: (String bottleId) => findBottle(BottleId(bottleId)).fold(
        Left<String, bool>.new,
        (bottle) => Right<String, bool>(bottle.isSome()),
      ),
    );
  }
}
