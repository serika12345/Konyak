import '../bottles/bottle_summary.dart';

sealed class BottleListLoadResult {
  const BottleListLoadResult();
}

final class LoadedBottleList extends BottleListLoadResult {
  const LoadedBottleList(this.bottles);

  final List<BottleSummary> bottles;
}

final class BottleListLoadFailure extends BottleListLoadResult {
  const BottleListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDetailLoadResult {
  const BottleDetailLoadResult();
}

final class LoadedBottleDetail extends BottleDetailLoadResult {
  const LoadedBottleDetail(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDetail extends BottleDetailLoadResult {
  const MissingBottleDetail({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDetailLoadFailure extends BottleDetailLoadResult {
  const BottleDetailLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleCreateLoadResult {
  const BottleCreateLoadResult();
}

final class CreatedBottle extends BottleCreateLoadResult {
  const CreatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class ExistingBottle extends BottleCreateLoadResult {
  const ExistingBottle({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleCreateLoadFailure extends BottleCreateLoadResult {
  const BottleCreateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadResult();
}

final class ExportedBottleArchive extends BottleArchiveExportLoadResult {
  const ExportedBottleArchive({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;
}

final class BottleArchiveExportLoadFailure
    extends BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadResult();
}

final class ImportedBottleArchive extends BottleArchiveImportLoadResult {
  const ImportedBottleArchive(this.bottle);

  final BottleSummary bottle;
}

final class BottleArchiveImportLoadFailure
    extends BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleUpdateLoadResult {
  const BottleUpdateLoadResult();
}

final class UpdatedBottle extends BottleUpdateLoadResult {
  const UpdatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleUpdate extends BottleUpdateLoadResult {
  const MissingBottleUpdate({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleUpdateLoadFailure extends BottleUpdateLoadResult {
  const BottleUpdateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDeleteLoadResult {
  const BottleDeleteLoadResult();
}

final class DeletedBottle extends BottleDeleteLoadResult {
  const DeletedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDelete extends BottleDeleteLoadResult {
  const MissingBottleDelete({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDeleteLoadFailure extends BottleDeleteLoadResult {
  const BottleDeleteLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
