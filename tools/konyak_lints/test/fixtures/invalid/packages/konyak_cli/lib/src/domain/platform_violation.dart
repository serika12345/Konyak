part of '../../../konyak_cli.dart';

String leakedPlatformEnvironment() {
  return Platform.environment['HOME'] ?? '';
}

String leakedPlatformVersion() {
  return Platform.operatingSystemVersion;
}
