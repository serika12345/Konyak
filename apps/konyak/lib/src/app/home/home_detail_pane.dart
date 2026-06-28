import 'package:flutter/material.dart';

import '../bottles/bottle_detail.dart';
import 'home_contracts.dart';

class KonyakHomeDetailPane extends StatelessWidget {
  const KonyakHomeDetailPane({
    super.key,
    required this.state,
    required this.menuActions,
    required this.bottleActions,
    required this.programActions,
    required this.winetricksActions,
    required this.navigationActions,
  });

  final KonyakHomeDetailState state;
  final KonyakHomeMenuActions menuActions;
  final KonyakBottleActions bottleActions;
  final KonyakProgramActions programActions;
  final KonyakWinetricksActions winetricksActions;
  final KonyakHomeNavigationActions navigationActions;

  @override
  Widget build(BuildContext context) {
    return KonyakBottleDetail(
      state: state,
      menuActions: menuActions,
      bottleActions: bottleActions,
      programActions: programActions,
      winetricksActions: winetricksActions,
      navigationActions: navigationActions,
    );
  }
}
