part of '../../../konyak_cli.dart';

class DartIoDomainLeak {
  const DartIoDomainLeak();
}

Object leakedDartIoFactory() {
  return const DartIoDomainLeak();
}
