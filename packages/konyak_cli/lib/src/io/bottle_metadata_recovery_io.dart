import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_metadata_recovery_models.dart';
import '../domain/bottle/bottle_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'bottle_metadata_json.dart';
import 'repository_storage_io.dart';

const invalidProgramProfilesMessage =
    'Bottle metadata contains invalid program profile records.';
const invalidBottleMetadataMessage =
    'Bottle metadata contains an invalid record.';
const symlinkedBottleMetadataMessage =
    'Bottle metadata uses an unsupported symbolic link.';
const bottleMetadataNotRepairableMessage =
    'Bottle metadata is not repairable by this action.';

sealed class BottleMetadataInspection {
  const BottleMetadataInspection();
}

final class ValidBottleMetadata extends BottleMetadataInspection {
  const ValidBottleMetadata(this.bottle);

  final BottleRecord bottle;
}

final class InvalidBottleMetadata extends BottleMetadataInspection {
  const InvalidBottleMetadata({required this.summary, required this.recovery});

  final InvalidBottleSummary summary;
  final BottleMetadataRecovery recovery;
}

sealed class BottleMetadataRecovery {
  const BottleMetadataRecovery();
}

final class NoBottleMetadataRecovery extends BottleMetadataRecovery {
  const NoBottleMetadataRecovery();
}

final class DiscardInvalidProgramProfilesRecovery
    extends BottleMetadataRecovery {
  const DiscardInvalidProgramProfilesRecovery({
    required this.bottle,
    required this.originalMetadata,
  });

  final BottleRecord bottle;
  final String originalMetadata;
}

BottleMetadataInspection inspectBottleMetadata({
  required String bottlePath,
  required BottleStorageId storageId,
}) {
  final metadataPath = joinPath(bottlePath, const ['metadata.json']);
  if (_isSymbolicLink(metadataPath)) {
    return _invalidMetadataInspection(
      bottlePath: bottlePath,
      storageId: storageId,
      message: symlinkedBottleMetadataMessage,
    );
  }

  try {
    final originalMetadata = File(metadataPath).readAsStringSync();
    final decoded = jsonDecode(originalMetadata);
    if (decoded is! Map<String, dynamic>) {
      return _invalidMetadataInspection(
        bottlePath: bottlePath,
        storageId: storageId,
        message: 'Bottle metadata must be an object.',
      );
    }
    if (decoded['schemaVersion'] != cliSchemaVersion) {
      return _invalidMetadataInspection(
        bottlePath: bottlePath,
        storageId: storageId,
        message: 'Unsupported bottle metadata schema version.',
      );
    }

    final rawBottle = decoded['bottle'];
    final parsedBottle = bottleRecordFromJson(rawBottle);
    final validBottle = parsedBottle.filter(
      (bottle) => _matchesStorageLocation(
        bottle: bottle,
        bottlePath: bottlePath,
        storageId: storageId,
      ),
    );
    return validBottle.match(
      () => _inspectInvalidBottleRecord(
        rawBottle: rawBottle,
        originalMetadata: originalMetadata,
        bottlePath: bottlePath,
        storageId: storageId,
      ),
      ValidBottleMetadata.new,
    );
  } on FormatException {
    return _invalidMetadataInspection(
      bottlePath: bottlePath,
      storageId: storageId,
      message: invalidBottleMetadataMessage,
    );
  } on FileSystemException catch (error) {
    return _invalidMetadataInspection(
      bottlePath: bottlePath,
      storageId: storageId,
      message: error.message,
    );
  }
}

BottleMetadataInspection _inspectInvalidBottleRecord({
  required Object? rawBottle,
  required String originalMetadata,
  required String bottlePath,
  required BottleStorageId storageId,
}) {
  final repairableBottle = _bottleWithoutInvalidProfiles(
    rawBottle: rawBottle,
    bottlePath: bottlePath,
    storageId: storageId,
  );
  return repairableBottle.match(
    () => _invalidMetadataInspection(
      bottlePath: bottlePath,
      storageId: storageId,
      message: invalidBottleMetadataMessage,
    ),
    (bottle) => InvalidBottleMetadata(
      summary: InvalidBottleSummary(
        storageId: storageId,
        path: BottlePath(bottlePath),
        code: InvalidBottleMetadataCode.invalidProgramProfiles,
        message: invalidProgramProfilesMessage,
        recoveryActions: const <BottleMetadataRecoveryAction>[
          BottleMetadataRecoveryAction.discardInvalidProfiles,
        ],
      ),
      recovery: DiscardInvalidProgramProfilesRecovery(
        bottle: bottle,
        originalMetadata: originalMetadata,
      ),
    ),
  );
}

InvalidBottleMetadata _invalidMetadataInspection({
  required String bottlePath,
  required BottleStorageId storageId,
  required String message,
}) {
  return InvalidBottleMetadata(
    summary: InvalidBottleSummary(
      storageId: storageId,
      path: BottlePath(bottlePath),
      code: InvalidBottleMetadataCode.invalidBottleMetadata,
      message: message,
    ),
    recovery: const NoBottleMetadataRecovery(),
  );
}

Option<BottleRecord> _bottleWithoutInvalidProfiles({
  required Object? rawBottle,
  required String bottlePath,
  required BottleStorageId storageId,
}) {
  if (rawBottle is! Map<String, dynamic> ||
      !rawBottle.containsKey('profiles')) {
    return const Option.none();
  }

  final withoutProfiles = Map<String, dynamic>.of(rawBottle)
    ..remove('profiles');
  return bottleRecordFromJson(withoutProfiles).filter(
    (bottle) => _matchesStorageLocation(
      bottle: bottle,
      bottlePath: bottlePath,
      storageId: storageId,
    ),
  );
}

bool _matchesStorageLocation({
  required BottleRecord bottle,
  required String bottlePath,
  required BottleStorageId storageId,
}) {
  return bottle.id.value == storageId.value &&
      normalizeFilesystemPath(File(bottle.path.value).absolute.path) ==
          normalizeFilesystemPath(File(bottlePath).absolute.path);
}

bool _isSymbolicLink(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.link;
}

String atomicallyReplaceBottleMetadataWithBackup({
  required String bottlePath,
  required BottleRecord bottle,
  required String expectedOriginalMetadata,
}) {
  final metadata = File(joinPath(bottlePath, const ['metadata.json']));
  final uniqueSuffix = DateTime.now().toUtc().microsecondsSinceEpoch;
  final backup = File('${metadata.path}.backup-$uniqueSuffix');
  final temporary = File('${metadata.path}.repair-$uniqueSuffix.tmp');
  final originalBytes = metadata.readAsBytesSync();
  if (utf8.decode(originalBytes) != expectedOriginalMetadata) {
    throw FileSystemException(
      'Bottle metadata changed during repair.',
      metadata.path,
    );
  }

  backup.createSync(exclusive: true);
  backup.writeAsBytesSync(originalBytes, flush: true);
  try {
    temporary.createSync(exclusive: true);
    temporary.writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(bottleMetadataDocumentJson(bottle)),
      flush: true,
    );
    temporary.renameSync(metadata.path);
  } finally {
    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
  }

  return backup.path;
}
