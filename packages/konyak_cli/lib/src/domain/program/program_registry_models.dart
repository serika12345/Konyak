final class RegistryValueUpdate {
  const RegistryValueUpdate({
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

final class RegistryValueQuery {
  const RegistryValueQuery({required this.key, required this.name});

  final String key;
  final String name;
}
