import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/executable_open_queue_state.dart';

void main() {
  test('models an empty executable-open queue explicitly', () {
    const state = ExecutableOpenQueueState.empty();

    expect(hasPendingExecutableOpenPaths(state), isFalse);

    switch (dequeueExecutableOpenPath(state)) {
      case EmptyExecutableOpenQueue(state: final nextState):
        expect(nextState, state);
      case DequeuedExecutableOpenPath():
        fail('empty queues must not produce a program path');
    }
  });

  test('dequeues executable-open paths FIFO from an immutable snapshot', () {
    final sourcePaths = <String>['/tmp/first.exe', '/tmp/second.exe'];
    final state = enqueueExecutableOpenPaths(
      state: const ExecutableOpenQueueState.empty(),
      paths: sourcePaths,
    );

    sourcePaths.add('/tmp/mutated.exe');

    final queuedWithThirdPath = enqueueExecutableOpenPaths(
      state: state,
      paths: const <String>['/tmp/third.exe'],
    );

    switch (dequeueExecutableOpenPath(queuedWithThirdPath)) {
      case DequeuedExecutableOpenPath(
        programPath: final programPath,
        state: final nextState,
      ):
        expect(programPath, '/tmp/first.exe');
        switch (dequeueExecutableOpenPath(nextState)) {
          case DequeuedExecutableOpenPath(
            programPath: final secondProgramPath,
            state: final secondNextState,
          ):
            expect(secondProgramPath, '/tmp/second.exe');
            switch (dequeueExecutableOpenPath(secondNextState)) {
              case DequeuedExecutableOpenPath(
                programPath: final thirdProgramPath,
                state: final thirdNextState,
              ):
                expect(thirdProgramPath, '/tmp/third.exe');
                expect(hasPendingExecutableOpenPaths(thirdNextState), isFalse);
              case EmptyExecutableOpenQueue():
                fail('third queued path was lost');
            }
          case EmptyExecutableOpenQueue():
            fail('second queued path was lost');
        }
      case EmptyExecutableOpenQueue():
        fail('first queued path was lost');
    }
  });
}
