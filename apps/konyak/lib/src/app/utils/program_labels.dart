import '../../cli/konyak_cli_client.dart';

String defaultProgramName(String path) {
  final normalized = path.trim().replaceAll(RegExp(r'/+$'), '');
  final separator = normalized.lastIndexOf('/');
  final fileName = separator == -1
      ? normalized
      : normalized.substring(separator + 1);
  final extension = fileName.lastIndexOf('.');
  if (extension <= 0) {
    return fileName;
  }

  return fileName.substring(0, extension);
}

String programDisplayName(BottleProgramSummary program) {
  final metadataName = program.metadata?.displayName.trim() ?? '';
  return metadataName.isEmpty ? program.name : metadataName;
}

String programSubtitle(BottleProgramSummary program) {
  final architecture = program.metadata?.architecture;
  if (architecture == null || architecture.trim().isEmpty) {
    return program.path;
  }

  return '$architecture - ${program.path}';
}
