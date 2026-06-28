import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';

class BottleProgramRecord {
  BottleProgramRecord({
    required String id,
    required String name,
    required String path,
    required String source,
    this.metadata = const Option.none(),
  }) : id = ProgramId(id),
       name = ProgramName(name),
       path = ProgramPath(path),
       source = ProgramSource(source);

  final ProgramId id;
  final ProgramName name;
  final ProgramPath path;
  final ProgramSource source;
  final Option<ProgramMetadataRecord> metadata;
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
  }) : architecture = architecture.map(ProgramArchitecture.new),
       fileDescription = fileDescription.map(ProgramFileDescription.new),
       productName = productName.map(ProgramProductName.new),
       companyName = companyName.map(ProgramCompanyName.new),
       fileVersion = fileVersion.map(ProgramFileVersion.new),
       productVersion = productVersion.map(ProgramProductVersion.new),
       iconPath = iconPath.map(ProgramIconPath.new);

  final Option<ProgramArchitecture> architecture;
  final Option<ProgramFileDescription> fileDescription;
  final Option<ProgramProductName> productName;
  final Option<ProgramCompanyName> companyName;
  final Option<ProgramFileVersion> fileVersion;
  final Option<ProgramProductVersion> productVersion;
  final Option<ProgramIconPath> iconPath;

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

class WineProcessRecord {
  WineProcessRecord({
    required String bottleId,
    required String processId,
    required String executable,
    Option<String> hostPath = const Option.none(),
    this.metadata = const Option.none(),
  }) : bottleId = BottleId(bottleId),
       processId = WineProcessId(processId),
       executable = ProgramExecutable(executable),
       hostPath = hostPath.map(ProgramPath.new);

  final BottleId bottleId;
  final WineProcessId processId;
  final ProgramExecutable executable;
  final Option<ProgramPath> hostPath;
  final Option<ProgramMetadataRecord> metadata;
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

class WinetricksVerbRecord {
  WinetricksVerbRecord({
    required String id,
    required this.name,
    required this.description,
  }) : id = WinetricksVerbId(id);

  final WinetricksVerbId id;
  final String name;
  final String description;
}

class WinetricksCategoryRecord {
  WinetricksCategoryRecord({
    required String id,
    required this.name,
    required List<WinetricksVerbRecord> verbs,
  }) : id = WinetricksCategoryId(id),
       verbs = List.unmodifiable(verbs);

  final WinetricksCategoryId id;
  final String name;
  final List<WinetricksVerbRecord> verbs;
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
