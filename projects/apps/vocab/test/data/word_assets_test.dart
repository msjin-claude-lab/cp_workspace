import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/word.dart';

/// 실제 내장 단어 파일(assets/words/*.json)을 검사한다.
/// 칸마다 있어야 할 단어 수는 [_expectedCount](초등 800개 — docs/plan-words-phase1.md,
/// 중등 700개 — docs/plan-words-phase2.md, 고등 1,500개 — docs/plan-words-phase3.md,
/// 심화 3,604개 — docs/plan-words-phase4.md).

/// 칸마다 있어야 할 단어 수. 초등은 CEFR-J A1에서 고른 800개(267 · 267 · 266),
/// 중등은 CEFR-J A1·A2에서 고른 700개(234 · 233 · 233), 고등은 1,500개(500 · 500 · 500).
const _expectedCount = {
  Cell.elementaryEasy: 267,
  Cell.elementaryMedium: 267,
  Cell.elementaryHard: 266,
  Cell.middleEasy: 234,
  Cell.middleMedium: 233,
  Cell.middleHard: 233,
  Cell.highEasy: 500,
  Cell.highMedium: 500,
  Cell.highHard: 500,
  Cell.advancedEasy: 1201,
  Cell.advancedMedium: 1200,
  Cell.advancedHard: 1200,
};

/// 단어를 묶음으로 나눠 넣는 중인 칸 — 이 칸만 개수를 "0개 이상, 기대값 이하"로 본다.
/// 나머지 칸은 늘 정확히 기대값이다. 지금은 심화 세 칸(4차 — 단어를 묶음으로 넣는 중). 마지막 묶음 뒤 비운다
/// (docs/plan-words-phase3.md 3·4단계 방식).
/// 옛 번호가 섞이는 것은 아래 번호 형식 검사(`w-\d{4}`만)가 잡는다.
const _filling = <Cell>{
  Cell.advancedEasy,
  Cell.advancedMedium,
  Cell.advancedHard,
};

/// 단어 번호: 칸과 무관한 새 번호(`w-0001`)만. 예전 칸별 번호(`ee-001` 등)는 초·중·고 모두
/// CEFR-J로 바꾸며 지웠고 DB 8·9·10판이 그 기록도 지웠다 — 다시 들어오면 여기서 잡힌다.
final _idPattern = RegExp(r'^w-\d{4}$');
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
        expect(
          seen[w.meaning],
          isNull,
          reason: '${cell.id} "${w.meaning}": ${seen[w.meaning]}와 ${w.id}',
        );
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

  test('넣지 않기로 한 말(심화 목록의 x 줄)이 어느 칸에도 없다', () {
    final lines = File('docs/wordlist/tiers-advanced.csv').readAsLinesSync();
    final excluded = <String>{
      for (final line in lines)
        if (!line.startsWith('#') && !line.startsWith('word,'))
          if (line.split(',') case [final word, 'x', ...]) word.toLowerCase(),
    };
    // 사용자가 정한 넷은 늘 들어 있어야 한다. 목록이 늘어도(고정 뒤 빼기로 한 말) 이 시험은 고치지 않는다
    expect(excluded, containsAll(['bust', 'gay', 'sex', 'suicide']));
    for (final cell in Cell.values) {
      for (final w in _read(cell)) {
        expect(
          excluded.contains(w.word.toLowerCase()),
          isFalse,
          reason: '${cell.id} ${w.id}: ${w.word}',
        );
      }
    }
  });

  test('예문에 그 영단어가 들어 있다', () {
    for (final cell in Cell.values) {
      for (final w in _read(cell)) {
        expect(
          w.example.toLowerCase(),
          contains(w.word.toLowerCase()),
          reason: w.id,
        );
      }
    }
  });
}
