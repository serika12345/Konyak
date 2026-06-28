import 'runtime_models.dart';

abstract interface class RuntimeCatalog {
  List<RuntimeRecord> listRuntimes();
}

class StaticRuntimeCatalog implements RuntimeCatalog {
  StaticRuntimeCatalog(Iterable<RuntimeRecord> runtimes)
    : _runtimes = List.unmodifiable(runtimes);

  final List<RuntimeRecord> _runtimes;

  @override
  List<RuntimeRecord> listRuntimes() {
    return List.unmodifiable(_runtimes);
  }
}
