part of '../../../konyak_cli.dart';

final class _RegistryValueUpdate {
  const _RegistryValueUpdate({
    required this.key,
    required this.name,
    required this.type,
    required this.data,
  });

  final String key;
  final String name;
  final String type;
  final String data;
}

final class _RegistryValueQuery {
  const _RegistryValueQuery({required this.key, required this.name});

  final String key;
  final String name;
}
