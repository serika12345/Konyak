import '../../domain/runtime/host_environment.dart';
import '../../repository/repository_exceptions.dart';
import '../../shared/common_helpers.dart';

String desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String linuxApplicationsHome(HostEnvironment environment) {
  return joinPath(linuxDataHome(environment), const <String>['applications']);
}

String linuxDataHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('XDG_DATA_HOME')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .match(
              () => throw const BottleRepositoryException(
                'Unable to resolve Linux data directory.',
              ),
              (home) => joinPath(home, const <String>['.local', 'share']),
            ),
        (xdgDataHome) => xdgDataHome,
      );
}
