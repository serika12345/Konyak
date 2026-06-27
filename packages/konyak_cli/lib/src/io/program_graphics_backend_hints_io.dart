part of '../../konyak_cli.dart';

class DartIoProgramGraphicsBackendHintsInspector {
  const DartIoProgramGraphicsBackendHintsInspector();

  ProgramGraphicsBackendHintsInspectionResult inspect({
    required String programPath,
    required KonyakHostPlatform hostPlatform,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return ProgramGraphicsBackendHintsMissingProgram(programPath);
      }

      return ProgramGraphicsBackendHintsInspected(
        _programGraphicsBackendHintsFromPortableExecutable(
          programPath: programPath,
          hostPlatform: hostPlatform,
          image: _PortableExecutableImage.parse(file.readAsBytesSync()),
        ),
      );
    } on FileSystemException catch (error) {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: error.message,
      );
    } on FormatException catch (error) {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: error.message,
      );
    } on RangeError {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: 'Program file could not be inspected.',
      );
    }
  }
}
