import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/word.dart';

/// 실제 내장 단어 파일(assets/words/*.json)을 검사한다.
/// 아직 안 쓴 칸은 빈 목록이어도 되고, 쓴 칸은 정확히 50개여야 한다.
List<Word> _read(Cell cell) {
  final text = File(cell.assetPath).readAsStringSync();
  final list = jsonDecode(text) as List<dynamic>;
  return list.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
}

/// 칸 id의 머리글자: elementary_easy → ee
String _prefix(Cell cell) => '${cell.level.name[0]}${cell.difficulty.name[0]}';

void main() {
  test('모든 칸의 단어 파일이 읽히고, 쓴 칸은 50개다', () {
    for (final cell in Cell.values) {
      final words = _read(cell);
      expect(words.length, anyOf(0, Cell.targetWordCount), reason: cell.id);
    }
  });

  test('단어마다 id가 칸 머리글자-번호이고 필드가 비어 있지 않다', () {
    for (final cell in Cell.values) {
      final words = _read(cell);
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        final no = (i + 1).toString().padLeft(3, '0');
        expect(w.id, '${_prefix(cell)}-$no', reason: '${cell.id} ${w.word}');
        expect(w.word.trim(), isNotEmpty, reason: w.id);
        expect(w.meaning.trim(), isNotEmpty, reason: w.id);
        expect(w.example.trim(), isNotEmpty, reason: w.id);
        expect(w.exampleMeaning.trim(), isNotEmpty, reason: w.id);
      }
    }
  });

  test('같은 영단어가 두 번 나오지 않는다(칸을 넘어서도)', () {
    final seen = <String, String>{};
    for (final cell in Cell.values) {
      for (final w in _read(cell)) {
        final key = w.word.toLowerCase();
        expect(seen[key], isNull, reason: '${w.word}: ${seen[key]}와 ${w.id}');
        seen[key] = w.id;
      }
    }
  });

  test('예문에 그 영단어가 들어 있다', () {
    for (final cell in Cell.values) {
      for (final w in _read(cell)) {
        expect(w.example.toLowerCase(), contains(w.word.toLowerCase()),
            reason: w.id);
      }
    }
  });
}
