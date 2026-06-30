import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/files/file_picker_arguments.dart';

void main() {
  test('models absent initial directories explicitly', () {
    expect(
      filePickerInitialDirectoryFromPath(' '),
      const FilePickerInitialDirectory.inherited(),
    );
  });

  test('models present initial directories explicitly', () {
    expect(
      filePickerInitialDirectoryFromPath('/tmp/logs'),
      const FilePickerInitialDirectory.path('/tmp/logs'),
    );
  });

  test('models suggested file names explicitly', () {
    expect(
      filePickerSuggestedNameFromPath(path: '/tmp/logs/latest.log'),
      const FilePickerSuggestedName.name('latest.log'),
    );
    expect(
      filePickerSuggestedNameFromPath(path: ' ', fallback: 'latest.log'),
      const FilePickerSuggestedName.name('latest.log'),
    );
  });
}
