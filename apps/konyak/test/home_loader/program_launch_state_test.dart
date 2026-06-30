import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/program_launch_state.dart';

void main() {
  test('models concurrent program launches explicitly', () {
    final firstStart = startProgramLaunch(
      state: const ProgramLaunchState.idle(),
    );

    expect(firstStart.launchId, 0);
    expect(hasActiveProgramLaunches(firstStart.state), isTrue);
    expect(isProgramLaunchActive(state: firstStart.state, launchId: 0), isTrue);

    final secondStart = startProgramLaunch(state: firstStart.state);

    expect(secondStart.launchId, 1);
    expect(
      isProgramLaunchActive(state: secondStart.state, launchId: 0),
      isTrue,
    );
    expect(
      isProgramLaunchActive(state: secondStart.state, launchId: 1),
      isTrue,
    );

    final secondOnly = finishProgramLaunch(
      state: secondStart.state,
      launchId: 0,
    );

    expect(isProgramLaunchActive(state: secondOnly, launchId: 0), isFalse);
    expect(isProgramLaunchActive(state: secondOnly, launchId: 1), isTrue);

    final idle = finishProgramLaunch(state: secondOnly, launchId: 1);

    expect(hasActiveProgramLaunches(idle), isFalse);

    final thirdStart = startProgramLaunch(state: idle);

    expect(thirdStart.launchId, 2);
    expect(isProgramLaunchActive(state: thirdStart.state, launchId: 2), isTrue);
  });
}
