import 'package:flutter/widgets.dart';

import 'src/app/konyak_app.dart';

export 'src/app/app_platform.dart' show KonyakPlatform;
export 'src/app/konyak_app.dart' show KonyakApp;

void main() {
  runApp(KonyakApp(enableBackgroundServices: true));
}
