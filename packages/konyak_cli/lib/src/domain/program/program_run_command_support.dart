import '../shared/domain_value_objects.dart';
import 'program_run_models.dart';

const _unsupportedProfileInstallWinetricksVerbIds = <String>{'steam'};

bool isSupportedWinetricksVerb(WinetricksVerbId verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb.value) &&
      !isUnsupportedProfileInstallWinetricksVerb(verb);
}

bool isUnsupportedProfileInstallWinetricksVerb(WinetricksVerbId verb) {
  return _unsupportedProfileInstallWinetricksVerbIds.contains(
    verb.value.toLowerCase(),
  );
}

String winedbgAttachProcessId(WineProcessId processId) {
  final normalized = processId.value.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}

WinedbgCommandPlan winedbgProcessListPlan() {
  return WinedbgCommandPlan(
    command: WinedbgCommand('info proc'),
    logFileName: ProgramLogFileName('wine-processes.log'),
    trailingArguments: ProgramRunArguments(const <String>[]),
  );
}

WinedbgCommandPlan winedbgProcessKillPlan(WineProcessId processId) {
  return WinedbgCommandPlan(
    command: WinedbgCommand('kill'),
    logFileName: ProgramLogFileName('wine-process-kill.log'),
    trailingArguments: ProgramRunArguments(<String>[
      winedbgAttachProcessId(processId),
    ]),
  );
}
