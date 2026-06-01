part of '../konyak_cli.dart';

class BottleProgramRecord {
  const BottleProgramRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    this.metadata,
  });

  final String id;
  final String name;
  final String path;
  final String source;
  final ProgramMetadataRecord? metadata;

  Map<String, Object?> toJson() {
    final programMetadata = metadata;

    return <String, Object?>{
      'id': id,
      'name': name,
      'path': path,
      'source': source,
      if (programMetadata != null) 'metadata': programMetadata.toJson(),
    };
  }
}

class ProgramMetadataRecord {
  const ProgramMetadataRecord({
    this.architecture,
    this.fileDescription,
    this.productName,
    this.companyName,
    this.fileVersion,
    this.productVersion,
    this.iconPath,
  });

  final String? architecture;
  final String? fileDescription;
  final String? productName;
  final String? companyName;
  final String? fileVersion;
  final String? productVersion;
  final String? iconPath;

  bool get isEmpty {
    return architecture == null &&
        fileDescription == null &&
        productName == null &&
        companyName == null &&
        fileVersion == null &&
        productVersion == null &&
        iconPath == null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (architecture != null) 'architecture': architecture,
      if (fileDescription != null) 'fileDescription': fileDescription,
      if (productName != null) 'productName': productName,
      if (companyName != null) 'companyName': companyName,
      if (fileVersion != null) 'fileVersion': fileVersion,
      if (productVersion != null) 'productVersion': productVersion,
      if (iconPath != null) 'iconPath': iconPath,
    };
  }
}

class WineProcessRecord {
  const WineProcessRecord({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata,
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final ProgramMetadataRecord? metadata;

  Map<String, Object?> toJson() {
    final processMetadata = metadata;

    return <String, Object?>{
      'bottleId': bottleId,
      'processId': processId,
      'executable': executable,
      if (hostPath != null) 'hostPath': hostPath,
      if (processMetadata != null) 'metadata': processMetadata.toJson(),
    };
  }
}

abstract interface class ProgramMetadataExtractor {
  ProgramMetadataRecord? extract({
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
