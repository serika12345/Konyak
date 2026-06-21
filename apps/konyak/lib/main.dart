import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import 'src/app/konyak_app.dart';

export 'src/app/app_platform.dart' show KonyakPlatform;
export 'src/app/konyak_app.dart' show KonyakApp;

void main(List<String> args) {
  final environment = Platform.environment;
  runApp(
    KonyakApp(
      initialExecutablePaths: args,
      executableOpenAutoRunBottleId:
          environment['KONYAK_ENABLE_SMOKE_HOOKS'] == '1'
          ? environment['KONYAK_SMOKE_OPEN_EXECUTABLE_AUTO_RUN_BOTTLE_ID']
          : null,
      enableBackgroundServices: true,
    ),
  );
}
