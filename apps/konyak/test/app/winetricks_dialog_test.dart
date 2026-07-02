import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/winetricks_dialog.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';

void main() {
  test('models winetricks dialog decisions explicitly', () {
    expect(
      const WinetricksVerbDecision.install('vcrun2022'),
      isA<InstallWinetricksVerb>(),
    );
    expect(
      const WinetricksVerbDecision.cancelled(),
      isA<CancelledWinetricksDialog>(),
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
