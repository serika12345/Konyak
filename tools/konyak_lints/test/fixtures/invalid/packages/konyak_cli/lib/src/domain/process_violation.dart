part of '../../../konyak_cli.dart';

int leakedProcessRunSync() {
  return Process.runSync('echo', const <String>[]).exitCode;
}
