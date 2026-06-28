import 'cli_default_runner.dart';
import 'cli_result_model.dart';

CliResult runCli(List<String> arguments) {
  return runCliWithDefaultIo(arguments);
}

Future<CliResult> runCliStreaming(List<String> arguments) {
  return runCliStreamingWithDefaultIo(arguments);
}
