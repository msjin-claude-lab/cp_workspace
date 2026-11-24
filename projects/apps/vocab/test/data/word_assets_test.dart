import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/word.dart';

/// 실제 내장 단어 파일(assets/words/*.json)을 검사한다.
/// 칸마다 있어야 할 단어 수는 [_expectedCount](초등 800개 — docs/plan-words-phase1.md,
/// 중등 700개 — docs/plan-words-phase2.md).

/// 칸마다 있어야 할 단어 수. 초등은 CEFR-J A1에서 고른 800개(267 · 267 · 266),
/// 중등은 CEFR-J A1·A2에서 고른 700개(234 · 233 · 233), 고등은 차례가 올 때까지 50개.
const _expectedCount = {
  Cell.elementaryEasy: 267,
  Cell.elementaryMedium: 267,
  Cell.elementaryHard: 266,
  Cell.middleEasy: 234,
  Cell.middleMedium: 233,
  Cell.middleHard: 233,
  Cell.highEasy: 50,
  Cell.highMedium: 50,
  Cell.highHard: 50,
};

/// 단어를 묶음으로 나눠 넣는 중인 칸 — 이 칸만 개수를 "0개 이상, 기대값 이하"로 본다.
/// 나머지 칸은 늘 정확히 기대값이다. 마지막 묶음을 넣은 뒤 빈 집합으로 바꿔
/// "정확히 기대값"을 확인한다(docs/plan-words-phase2.md 3·4단계).
const _filling = <Cell>{};

/// 단어 번호: 예전 번호(`ee-001`)이거나 칸과 무관한 새 번호(`w-0001`).
final _idPattern = RegExp(r'^([emh][emh]-\d{3}|w-\d{4})$');
List<Word> _read(Cell cell) {
  final text = File(cell.assetPath).readAsStringSync();
  final list = jsonDecode(text) as List<dynamic>;
  return list.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
}

void main() {
  test('모든 칸의 단어 파일이 읽히고 칸마다 정해진 개수다', () {
    for (final cell in Cell.values) {
      final count = _read(cell).length;
      final expected = _expectedCount[cell]!;
      if (_filling.contains(cell)) {
        expect(count, inInclusiveRange(0, expected), reason: cell.id);
      } else {
        expect(count, expected, reason: cell.id);
      }
    }
  });

  test('뜻을 쉼표로 나눈 낱말이 같은 칸 안에서 겹치지 않는다(뜻→영 문제의 정답이 둘로 보이지 않게)', () {
    for (final cell in Cell.values) {
      final seen = <String, String>{};
      for (final w in _read(cell)) {
        for (final part in w.meaning.split(',').map((p) => p.trim())) {
          expect(
            seen[part],
            isNull,
            reason: '${cell.id} "$part": ${seen[part]}와 ${w.id}(${w.word})',
          );
          seen[part] = '${w.id}(${w.word})';
        }
      }
    }
  });

  test('같은 칸 안에 뜻이 같은 단어가 없다(4지선다 보기가 겹치지 않게)', () {
    for (final cell in Cell.values) {
      final seen = <String, String>{};
      for (final w in _read(cell)) {
        expect(seen[w.meaning], isNull,
            reason: '${cell.id} "${w.meaning}": ${seen[w.meaning]}와 ${w.id}');
        seen[w.meaning] = w.id;
      }
    }
  });

  test('단어 번호가 형식에 맞고 전체에서 겹치지 않으며 필드가 비어 있지 않다', () {
    final ids = <String, String>{};
    for (final cell in Cell.values) {
      final words = _read(cell);
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        expect(_idPattern.hasMatch(w.id), isTrue, reason: '${cell.id} ${w.id}');
        expect(ids[w.id], isNull, reason: '${w.id}: ${ids[w.id]}와 ${cell.id}');
        ids[w.id] = cell.id;
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
