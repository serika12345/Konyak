part of '../../../konyak_cli.dart';

String _desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _linuxApplicationsHome(HostEnvironment environment) {
  return _joinPath(_linuxDataHome(environment), const <String>['applications']);
}

String _linuxDataHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('XDG_DATA_HOME')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .match(
              () => throw const BottleRepositoryException(
                'Unable to resolve Linux data directory.',
              ),
              (home) => _joinPath(home, const <String>['.local', 'share']),
            ),
        (xdgDataHome) => xdgDataHome,
      );
}
