enum GptkImportVersion {
  auto,
  gptk3,
  gptk4;

  List<String> get cliArguments {
    return switch (this) {
      GptkImportVersion.auto => const <String>[],
      GptkImportVersion.gptk3 => const <String>['--gptk-version', '3'],
      GptkImportVersion.gptk4 => const <String>['--gptk-version', '4'],
    };
  }
}
