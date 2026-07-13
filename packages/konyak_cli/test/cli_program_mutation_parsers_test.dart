import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/src/cli/cli_program_mutation_parsers.dart';
import 'package:test/test.dart';

void main() {
  test('parses program pin requests as explicit options', () {
    final request = _expectSome(
      parseJsonProgramPinRequestOption(const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ]),
    );

    expect(request.bottleId.value, 'steam');
    expect(request.name.value, 'Steam');
    expect(request.programPath.value, '/downloads/Steam.exe');
  });

  test('rejects incomplete program mutation requests explicitly', () {
    _expectNone(
      parseJsonProgramPinRequestOption(const [
        'pin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ]),
    );
    _expectNone(
      parseJsonProgramRenameRequestOption(const [
        'rename-pinned-program',
        'steam',
        '--program',
        '  ',
        '--name',
        'Steam',
        '--json',
      ]),
    );
    _expectNone(
      parseJsonProgramSettingsUpdateRequestOption(const [
        'set-program-settings',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--settings-json',
        '{',
        '--json',
      ]),
    );
  });

  test('parses pinned program launcher requests as explicit options', () {
    final request = _expectSome(
      parseJsonPinnedProgramLaunchCliRequestOption(const [
        'launch-pinned-program',
        '--manifest',
        '/launchers/steam.json',
        '--json',
      ]),
    );

    expect(request.manifestPath, '/launchers/steam.json');
  });

  test('parses program profile requests as explicit options', () {
    final installRequest = _expectSome(
      parseJsonProgramProfileInstallRequestOption(const [
        'install-program-profile',
        'steam',
        '--bottle',
        'games',
        '--json',
      ]),
    );

    expect(installRequest.profileId.value, 'steam');
    expect(installRequest.bottleId.value, 'games');
    expect(installRequest.emitProgress, isFalse);

    final progressInstallRequest = _expectSome(
      parseJsonProgramProfileInstallRequestOption(const [
        'install-program-profile',
        'steam',
        '--bottle',
        'games',
        '--progress-json',
        '--json',
      ]),
    );
    expect(progressInstallRequest.emitProgress, isTrue);

    final applyRequest = _expectSome(
      parseJsonProgramProfileApplyRequestOption(const [
        'apply-program-profile',
        'steam',
        '--bottle',
        'steam',
        '--program',
        r'C:\Program Files (x86)\Steam\Steam.exe',
        '--json',
      ]),
    );

    expect(applyRequest.profileId.value, 'steam');
    expect(applyRequest.bottleId.value, 'steam');
    expect(
      applyRequest.programPath.value,
      r'C:\Program Files (x86)\Steam\Steam.exe',
    );

    final repairRequest = _expectSome(
      parseJsonProgramProfileRepairRequestOption(const [
        'repair-profile',
        'steam',
        '--bottle',
        'steam',
        '--json',
      ]),
    );

    expect(repairRequest.profileId.value, 'steam');
    expect(repairRequest.bottleId.value, 'steam');
  });
}

T _expectSome<T>(Option<T> option) {
  return option.match(
    () => fail('Expected an option value.'),
    (value) => value,
  );
}

void _expectNone<T>(Option<T> option) {
  option.match(() => null, (_) => fail('Expected an empty option.'));
}
