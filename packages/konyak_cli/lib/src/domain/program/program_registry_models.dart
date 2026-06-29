import 'package:freezed_annotation/freezed_annotation.dart';

part 'program_registry_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RegistryValueUpdate with _$RegistryValueUpdate {
  const factory RegistryValueUpdate({
    required String key,
    required String name,
    required String type,
    required String data,
  }) = _RegistryValueUpdate;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RegistryValueQuery with _$RegistryValueQuery {
  const factory RegistryValueQuery({
    required String key,
    required String name,
  }) = _RegistryValueQuery;
}
