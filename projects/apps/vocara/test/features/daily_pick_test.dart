import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocara/data/word.dart';
import 'package:vocara/features/today/daily_pick.dart';

import '../fakes.dart';

/// 오늘의 단어 고르기(2026-11-28 사용자 결정): 안 본 단어 → 오답 노트 → 가장 오래전에 본 단어.
void main() {
  final words = [
    for (var i = 1; i <= 8; i++) fakeWord('w-$i', 'word$i', '뜻$i'),
  ];

  List<String> ids(List<Word> picked) => [for (final w in picked) w.id];

  test('안 본 단어를 먼저 모두 고르고, 모자라면 오답 노트, 그래도 모자라면 가장 오래전에 본 단어 순', () {
    final picked = pickDailyWords(
      words: words,
      // w-1~w-6은 봤다(시각이 작을수록 오래전). w-7·w-8은 안 봤다
      lastViewed: {
        'w-1': 50,
        'w-2': 10,
        'w-3': 40,
        'w-4': 30,
        'w-5': 20,
        'w-6': 60,
      },
      wrongIds: ['w-6', 'w-7'], // w-7은 안 본 단어라 이미 앞에서 고른다
      count: 6,
      random: Random(1),
    );
    final result = ids(picked);
    expect(result, hasLength(6));
    // 앞 둘은 안 본 단어(순서는 무작위)
    expect(result.take(2).toSet(), {'w-7', 'w-8'});
    // 다음은 오답 노트(이미 고른 w-7은 건너뜀)
    expect(result[2], 'w-6');
    // 나머지는 가장 오래전에 본 것부터
    expect(result.skip(3), ['w-2', 'w-5', 'w-4']);
  });

  test('안 본 단어가 개수보다 많으면 안 본 단어만, 겹치지 않게 고른다', () {
    final picked = ids(
      pickDailyWords(
        words: words,
        lastViewed: {'w-1': 1},
        wrongIds: ['w-1'],
        count: 5,
        random: Random(2),
      ),
    );
    expect(picked, hasLength(5));
    expect(picked.toSet(), hasLength(5));
    expect(picked, isNot(contains('w-1')));
  });

  test('단어가 개수보다 적으면 있는 만큼, 단어가 없으면 빈 목록', () {
    expect(
      ids(
        pickDailyWords(
          words: words.take(3).toList(),
          lastViewed: const {},
          wrongIds: const [],
          count: 10,
          random: Random(3),
        ),
      ).toSet(),
      {'w-1', 'w-2', 'w-3'},
    );
    expect(
      pickDailyWords(
        words: const [],
        lastViewed: const {},
        wrongIds: const [],
        count: 10,
        random: Random(3),
      ),
      isEmpty,
    );
  });

  test('모두 봤고 오답도 없으면 가장 오래전에 본 것부터(같은 시각이면 단어 파일 순서)', () {
    final picked = pickDailyWords(
      words: words.take(4).toList(),
      lastViewed: {'w-1': 5, 'w-2': 5, 'w-3': 1, 'w-4': 9},
      wrongIds: const ['w-404'], // 단어 파일에 없는 오답은 건너뛴다
      count: 3,
      random: Random(4),
    );
    expect(ids(picked), ['w-3', 'w-1', 'w-2']);
  });
}
