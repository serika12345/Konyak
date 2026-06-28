part of '../../../konyak_cli.dart';

void leakedSerializationSink(StringSink output) {
  output.writeln(jsonEncode(<String, String>{'ok': 'true'}));
}
