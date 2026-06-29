import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'program_registry_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RegistryValueUpdate with _$RegistryValueUpdate {
  const factory RegistryValueUpdate({
    required ProgramRegistryKey key,
    required ProgramRegistryValueName name,
    required ProgramRegistryValueType type,
    required ProgramRegistryValueData data,
  }) = _RegistryValueUpdate;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RegistryValueQuery with _$RegistryValueQuery {
  const factory RegistryValueQuery({
    required ProgramRegistryKey key,
    required ProgramRegistryValueName name,
  }) = _RegistryValueQuery;
}
