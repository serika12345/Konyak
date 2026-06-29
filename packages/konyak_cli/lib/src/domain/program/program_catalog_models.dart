import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';

part 'program_catalog_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleProgramRecord with _$BottleProgramRecord {
  const BottleProgramRecord._();

  factory BottleProgramRecord({
    required ProgramId id,
    required ProgramName name,
    required ProgramPath path,
    required ProgramSource source,
    Option<ProgramMetadataRecord> metadata = const Option.none(),
  }) {
    return BottleProgramRecord._validated(
      id: id,
      name: name,
      path: path,
      source: source,
      metadata: metadata,
    );
  }

  const factory BottleProgramRecord._validated({
    required ProgramId id,
    required ProgramName name,
    required ProgramPath path,
    required ProgramSource source,
    required Option<ProgramMetadataRecord> metadata,
  }) = _BottleProgramRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramMetadataRecord with _$ProgramMetadataRecord {
  const ProgramMetadataRecord._();

  factory ProgramMetadataRecord({
    Option<ProgramArchitecture> architecture = const Option.none(),
    Option<ProgramFileDescription> fileDescription = const Option.none(),
    Option<ProgramProductName> productName = const Option.none(),
    Option<ProgramCompanyName> companyName = const Option.none(),
    Option<ProgramFileVersion> fileVersion = const Option.none(),
    Option<ProgramProductVersion> productVersion = const Option.none(),
    Option<ProgramIconPath> iconPath = const Option.none(),
  }) {
    return ProgramMetadataRecord._validated(
      architecture: architecture,
      fileDescription: fileDescription,
      productName: productName,
      companyName: companyName,
      fileVersion: fileVersion,
      productVersion: productVersion,
      iconPath: iconPath,
    );
  }

  const factory ProgramMetadataRecord._validated({
    required Option<ProgramArchitecture> architecture,
    required Option<ProgramFileDescription> fileDescription,
    required Option<ProgramProductName> productName,
    required Option<ProgramCompanyName> companyName,
    required Option<ProgramFileVersion> fileVersion,
    required Option<ProgramProductVersion> productVersion,
    required Option<ProgramIconPath> iconPath,
  }) = _ProgramMetadataRecord;

  bool get isEmpty {
    return architecture.isNone() &&
        fileDescription.isNone() &&
        productName.isNone() &&
        companyName.isNone() &&
        fileVersion.isNone() &&
        productVersion.isNone() &&
        iconPath.isNone();
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessRecord with _$WineProcessRecord {
  const WineProcessRecord._();

  factory WineProcessRecord({
    required BottleId bottleId,
    required WineProcessId processId,
    required ProgramExecutable executable,
    Option<ProgramPath> hostPath = const Option.none(),
    Option<ProgramMetadataRecord> metadata = const Option.none(),
  }) {
    return WineProcessRecord._validated(
      bottleId: bottleId,
      processId: processId,
      executable: executable,
      hostPath: hostPath,
      metadata: metadata,
    );
  }

  const factory WineProcessRecord._validated({
    required BottleId bottleId,
    required WineProcessId processId,
    required ProgramExecutable executable,
    required Option<ProgramPath> hostPath,
    required Option<ProgramMetadataRecord> metadata,
  }) = _WineProcessRecord;
}

abstract interface class ProgramMetadataExtractor {
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  });
}

abstract interface class AsyncProgramMetadataExtractor {
  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required ProgramPath programPath,
  });
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksVerbRecord with _$WinetricksVerbRecord {
  const WinetricksVerbRecord._();

  factory WinetricksVerbRecord({
    required WinetricksVerbId id,
    required WinetricksVerbName name,
    required WinetricksVerbDescription description,
  }) {
    return WinetricksVerbRecord._validated(
      id: id,
      name: name,
      description: description,
    );
  }

  const factory WinetricksVerbRecord._validated({
    required WinetricksVerbId id,
    required WinetricksVerbName name,
    required WinetricksVerbDescription description,
  }) = _WinetricksVerbRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinetricksCategoryRecord with _$WinetricksCategoryRecord {
  const WinetricksCategoryRecord._();

  factory WinetricksCategoryRecord({
    required WinetricksCategoryId id,
    required WinetricksCategoryName name,
    required List<WinetricksVerbRecord> verbs,
  }) {
    return WinetricksCategoryRecord._validated(
      id: id,
      name: name,
      verbs: List.unmodifiable(verbs),
    );
  }

  const factory WinetricksCategoryRecord._validated({
    required WinetricksCategoryId id,
    required WinetricksCategoryName name,
    required List<WinetricksVerbRecord> verbs,
  }) = _WinetricksCategoryRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class WinetricksVerbListResult with _$WinetricksVerbListResult {
  const WinetricksVerbListResult._();

  factory WinetricksVerbListResult.completed({
    required Iterable<WinetricksCategoryRecord> categories,
  }) {
    return WinetricksVerbListResult._completed(
      categories: categories.toIList(),
    );
  }

  const factory WinetricksVerbListResult._completed({
    required IList<WinetricksCategoryRecord> categories,
  }) = WinetricksVerbListCompleted;

  const factory WinetricksVerbListResult.failed(String message) =
      WinetricksVerbListFailed;
}
