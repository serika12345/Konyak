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
    required String id,
    required String name,
    required String path,
    required String source,
    Option<ProgramMetadataRecord> metadata = const Option.none(),
  }) {
    return BottleProgramRecord._validated(
      id: ProgramId(id),
      name: ProgramName(name),
      path: ProgramPath(path),
      source: ProgramSource(source),
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
    Option<String> architecture = const Option.none(),
    Option<String> fileDescription = const Option.none(),
    Option<String> productName = const Option.none(),
    Option<String> companyName = const Option.none(),
    Option<String> fileVersion = const Option.none(),
    Option<String> productVersion = const Option.none(),
    Option<String> iconPath = const Option.none(),
  }) {
    return ProgramMetadataRecord._validated(
      architecture: architecture.map(ProgramArchitecture.new),
      fileDescription: fileDescription.map(ProgramFileDescription.new),
      productName: productName.map(ProgramProductName.new),
      companyName: companyName.map(ProgramCompanyName.new),
      fileVersion: fileVersion.map(ProgramFileVersion.new),
      productVersion: productVersion.map(ProgramProductVersion.new),
      iconPath: iconPath.map(ProgramIconPath.new),
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
    required String bottleId,
    required String processId,
    required String executable,
    Option<String> hostPath = const Option.none(),
    Option<ProgramMetadataRecord> metadata = const Option.none(),
  }) {
    return WineProcessRecord._validated(
      bottleId: BottleId(bottleId),
      processId: WineProcessId(processId),
      executable: ProgramExecutable(executable),
      hostPath: hostPath.map(ProgramPath.new),
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
    required String programPath,
  });
}

abstract interface class AsyncProgramMetadataExtractor {
  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required String programPath,
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
    required String id,
    required String name,
    required String description,
  }) {
    return WinetricksVerbRecord._validated(
      id: WinetricksVerbId(id),
      name: name,
      description: description,
    );
  }

  const factory WinetricksVerbRecord._validated({
    required WinetricksVerbId id,
    required String name,
    required String description,
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
    required String id,
    required String name,
    required List<WinetricksVerbRecord> verbs,
  }) {
    return WinetricksCategoryRecord._validated(
      id: WinetricksCategoryId(id),
      name: name,
      verbs: List.unmodifiable(verbs),
    );
  }

  const factory WinetricksCategoryRecord._validated({
    required WinetricksCategoryId id,
    required String name,
    required List<WinetricksVerbRecord> verbs,
  }) = _WinetricksCategoryRecord;
}

sealed class WinetricksVerbListResult {
  const WinetricksVerbListResult();
}

class WinetricksVerbListCompleted extends WinetricksVerbListResult {
  WinetricksVerbListCompleted({
    required List<WinetricksCategoryRecord> categories,
  }) : categories = List.unmodifiable(categories);

  final List<WinetricksCategoryRecord> categories;
}

class WinetricksVerbListFailed extends WinetricksVerbListResult {
  const WinetricksVerbListFailed(this.message);

  final String message;
}
