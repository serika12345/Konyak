import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/files/program_file_picker.dart';

void main() {
  test('program file picker only accepts supported Windows program types', () {
    final groups = windowsProgramFileTypeGroups();

    expect(groups, hasLength(1));
    expect(groups.single.label, 'Windows programs');
    expect(groups.single.extensions, const ['exe', 'msi', 'bat', 'cmd', 'lnk']);
    expect(groups.any((group) => group.allowsAny), isFalse);
  });
}
