part of '../konyak_cli.dart';

class BottleProgramRecord {
  const BottleProgramRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    this.metadata = const Option.none(),
  });

  final String id;
  final String name;
  final String path;
  final String source;
  final Option<ProgramMetadataRecord> metadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'path': path,
      'source': source,
      ...metadata.match(
        () => const <String, Object?>{},
        (programMetadata) => <String, Object?>{
          'metadata': programMetadata.toJson(),
        },
      ),
    };
  }
}

class ProgramMetadataRecord {
  ProgramMetadataRecord({
    Option<String> architecture = const Option.none(),
    Option<String> fileDescription = const Option.none(),
    Option<String> productName = const Option.none(),
    Option<String> companyName = const Option.none(),
    Option<String> fileVersion = const Option.none(),
    Option<String> productVersion = const Option.none(),
    Option<String> iconPath = const Option.none(),
  }) : architecture = _requiredNonBlankMetadataOption(
         architecture,
         'architecture',
       ),
       fileDescription = _requiredNonBlankMetadataOption(
         fileDescription,
         'fileDescription',
       ),
       productName = _requiredNonBlankMetadataOption(
         productName,
         'productName',
       ),
       companyName = _requiredNonBlankMetadataOption(
         companyName,
         'companyName',
       ),
       fileVersion = _requiredNonBlankMetadataOption(
         fileVersion,
         'fileVersion',
       ),
       productVersion = _requiredNonBlankMetadataOption(
         productVersion,
         'productVersion',
       ),
       iconPath = _requiredNonBlankMetadataOption(iconPath, 'iconPath');

  final Option<String> architecture;
  final Option<String> fileDescription;
  final Option<String> productName;
  final Option<String> companyName;
  final Option<String> fileVersion;
  final Option<String> productVersion;
  final Option<String> iconPath;

  bool get isEmpty {
    return architecture.isNone() &&
        fileDescription.isNone() &&
        productName.isNone() &&
        companyName.isNone() &&
        fileVersion.isNone() &&
        productVersion.isNone() &&
        iconPath.isNone();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ..._metadataJsonField('architecture', architecture),
      ..._metadataJsonField('fileDescription', fileDescription),
      ..._metadataJsonField('productName', productName),
      ..._metadataJsonField('companyName', companyName),
      ..._metadataJsonField('fileVersion', fileVersion),
      ..._metadataJsonField('productVersion', productVersion),
      ..._metadataJsonField('iconPath', iconPath),
    };
  }
}

Option<String> _requiredNonBlankMetadataOption(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
}

Map<String, Object?> _metadataJsonField(String key, Option<String> value) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item},
  );
}

class WineProcessRecord {
  const WineProcessRecord({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata = const Option.none(),
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final Option<ProgramMetadataRecord> metadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId,
      'processId': processId,
      'executable': executable,
      if (hostPath != null) 'hostPath': hostPath,
      ...metadata.match(
        () => const <String, Object?>{},
        (processMetadata) => <String, Object?>{
          'metadata': processMetadata.toJson(),
        },
      ),
    };
  }
}

abstract interface class ProgramMetadataExtractor {
  Option<ProgramMetadataRecord> extract({
    required BottleRecord bottle,
    required String programPath,
  });
}

class WinetricksVerbRecord {
  const WinetricksVerbRecord({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class WinetricksCategoryRecord {
  WinetricksCategoryRecord({
    required this.id,
    required this.name,
    required List<WinetricksVerbRecord> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbRecord> verbs;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'verbs': verbs.map((verb) => verb.toJson()).toList(growable: false),
    };
  }
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

sealed class WinetricksScriptInstallResult {
  const WinetricksScriptInstallResult();
}

class WinetricksScriptInstallCompleted extends WinetricksScriptInstallResult {
  const WinetricksScriptInstallCompleted();
}

class WinetricksScriptInstallFailed extends WinetricksScriptInstallResult {
  const WinetricksScriptInstallFailed(this.message);

  final String message;
}
