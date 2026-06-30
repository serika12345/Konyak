import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/known_runtimes_state.dart';
import 'package:konyak/src/runtimes/runtime_summary.dart';

void main() {
  test('distinguishes pending runtime loading from a resolved empty list', () {
    const pending = KnownRuntimesState.pending();
    final loadedEmpty = KnownRuntimesState.loaded(const <RuntimeSummary>[]);

    expect(pending.isLoaded, isFalse);
    expect(pending.runtimes, isEmpty);
    expect(loadedEmpty.isLoaded, isTrue);
    expect(loadedEmpty.runtimes, isEmpty);
  });

  test('keeps loaded runtimes as an immutable snapshot', () {
    final runtime = _runtime(id: 'konyak-macos-wine');
    final source = <RuntimeSummary>[runtime];
    final loaded = KnownRuntimesState.loaded(source);

    source.clear();

    expect(loaded.runtimes, [runtime]);
    expect(loaded.runtimes.clear, throwsUnsupportedError);
  });
}

RuntimeSummary _runtime({required String id}) {
  return RuntimeSummary(
    id: id,
    name: id,
    platform: 'macos',
    architecture: 'x86_64',
    runnerKind: 'macosWine',
    isBundled: false,
    isUpdateable: true,
    isInstalled: true,
  );
}
