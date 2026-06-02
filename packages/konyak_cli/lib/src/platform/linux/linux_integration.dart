part of '../../../konyak_cli.dart';

String _desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _linuxApplicationsHome(HostEnvironment environment) {
  final xdgDataHome = environment.nonEmptyValue('XDG_DATA_HOME');
  if (xdgDataHome != null) {
    return _joinPath(xdgDataHome, const <String>['applications']);
  }

  final home = environment.nonEmptyValue('HOME');
  if (home != null) {
    return _joinPath(home, const <String>['.local', 'share', 'applications']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux applications directory.',
  );
}
