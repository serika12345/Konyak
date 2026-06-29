import 'package:fpdart/fpdart.dart';

import '../domain/program/program_catalog_models.dart';
import '../domain/shared/domain_value_objects.dart';

Map<String, Object?> bottleProgramRecordJson(BottleProgramRecord record) {
  return <String, Object?>{
    'id': record.id.value,
    'name': record.name.value,
    'path': record.path.value,
    'source': record.source.value,
    ...record.metadata.match(
      () => const <String, Object?>{},
      (metadata) => <String, Object?>{
        'metadata': programMetadataRecordJson(metadata),
      },
    ),
  };
}

Map<String, Object?> wineProcessRecordJson(WineProcessRecord record) {
  return <String, Object?>{
    'bottleId': record.bottleId.value,
    'processId': record.processId.value,
    'executable': record.executable.value,
    ..._metadataJsonField('hostPath', record.hostPath),
    ...record.metadata.match(
      () => const <String, Object?>{},
      (metadata) => <String, Object?>{
        'metadata': programMetadataRecordJson(metadata),
      },
    ),
  };
}

Map<String, Object?> programMetadataRecordJson(ProgramMetadataRecord metadata) {
  return <String, Object?>{
    ..._metadataJsonField('architecture', metadata.architecture),
    ..._metadataJsonField('fileDescription', metadata.fileDescription),
    ..._metadataJsonField('productName', metadata.productName),
    ..._metadataJsonField('companyName', metadata.companyName),
    ..._metadataJsonField('fileVersion', metadata.fileVersion),
    ..._metadataJsonField('productVersion', metadata.productVersion),
    ..._metadataJsonField('iconPath', metadata.iconPath),
  };
}

Map<String, Object?> winetricksVerbRecordJson(WinetricksVerbRecord verb) {
  return <String, Object?>{
    'id': verb.id.value,
    'name': verb.name.value,
    'description': verb.description.value,
  };
}

Map<String, Object?> winetricksCategoryRecordJson(
  WinetricksCategoryRecord category,
) {
  return <String, Object?>{
    'id': category.id.value,
    'name': category.name.value,
    'verbs': category.verbs
        .map(winetricksVerbRecordJson)
        .toList(growable: false),
  };
}

Map<String, Object?> _metadataJsonField(
  String key,
  Option<StringDomainValueObject> value,
) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item.value},
  );
}
