import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Konyak localizations are backed by English and Japanese ARB files', () {
    final english = _readArb('lib/src/l10n/konyak_en.arb');
    final japanese = _readArb('lib/src/l10n/konyak_ja.arb');

    expect(english['@@locale'], 'en');
    expect(japanese['@@locale'], 'ja');
    expect(english['konyakSettings'], 'Konyak Settings');
    expect(japanese['konyakSettings'], 'Konyak 設定');
    expect(english['installingKonyakUpdate'], contains('{label}'));
    expect(japanese['installingKonyakUpdate'], contains('{label}'));

    final englishKeys = _messageKeys(english);
    final japaneseKeys = _messageKeys(japanese);
    expect(japaneseKeys, englishKeys);
    expect(
      englishKeys.where((key) => RegExp(r'\d$').hasMatch(key)),
      isEmpty,
      reason: 'ARB message keys should describe usage, not collision suffixes.',
    );
    expect(
      englishKeys.where((key) => key.length > 80),
      isEmpty,
      reason: 'ARB message keys should be stable usage names, not source text.',
    );
  });
}

Map<String, Object?> _readArb(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Set<String> _messageKeys(Map<String, Object?> arb) {
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}
