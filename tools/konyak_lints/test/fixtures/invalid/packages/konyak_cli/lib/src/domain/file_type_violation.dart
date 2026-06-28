part of '../../../konyak_cli.dart';

bool leakedFileType(File file) {
  return file.existsSync();
}
