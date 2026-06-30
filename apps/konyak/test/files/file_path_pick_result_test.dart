import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/files/file_path_pick_result.dart';

void main() {
  test('models cancelled file picker selections explicitly', () {
    expect(
      filePathPickResultFromNullable(null),
      const FilePathPickResult.cancelled(),
    );
    expect(
      filePathPickResultFromNullable('   '),
      const FilePathPickResult.cancelled(),
    );
  });

  test('models picked file paths explicitly', () {
    const path = '/Users/example/setup.exe';

    expect(
      filePathPickResultFromNullable(path),
      const FilePathPickResult.picked(path),
    );
  });
}
