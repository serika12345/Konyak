import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/winetricks_dialog.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';

void main() {
  test('models dismissed winetricks dialogs explicitly', () {
    const installDecision = WinetricksVerbDecision.install('vcrun2022');

    expect(
      winetricksVerbDecisionFromNullable(null),
      const WinetricksVerbDecision.cancelled(),
    );
    expect(
      winetricksVerbDecisionFromNullable(installDecision),
      installDecision,
    );
  });

  test('models missing winetricks verb selections explicitly', () {
    final selection = winetricksVerbSelectionById(
      categories: const <WinetricksCategorySummary>[],
      verbId: 'vcrun2022',
    );

    expect(switch (selection) {
      SelectedWinetricksVerb() => '',
      NoWinetricksVerbSelection() => 'none',
    }, 'none');
  });

  test('selects winetricks verbs by id explicitly', () {
    const verb = WinetricksVerbSummary(
      id: 'vcrun2022',
      name: 'VC++ 2022',
      description: 'Runtime',
    );
    final selection = winetricksVerbSelectionById(
      categories: [
        WinetricksCategorySummary(
          id: 'dlls',
          name: 'DLLs',
          verbs: const [verb],
        ),
      ],
      verbId: 'vcrun2022',
    );

    expect(switch (selection) {
      SelectedWinetricksVerb(:final verb) => verb.id,
      NoWinetricksVerbSelection() => '',
    }, 'vcrun2022');
  });
}
