import '../runtimes/runtime_summary.dart';

sealed class KnownRuntimesState {
  const KnownRuntimesState();

  List<RuntimeSummary> get runtimes;
  bool get isLoaded;
}

final class KnownRuntimesPending extends KnownRuntimesState {
  const KnownRuntimesPending();

  @override
  List<RuntimeSummary> get runtimes => const <RuntimeSummary>[];

  @override
  bool get isLoaded => false;
}

final class KnownRuntimesLoaded extends KnownRuntimesState {
  KnownRuntimesLoaded(List<RuntimeSummary> runtimes)
    : runtimes = List.unmodifiable(runtimes);

  @override
  final List<RuntimeSummary> runtimes;

  @override
  bool get isLoaded => true;
}
