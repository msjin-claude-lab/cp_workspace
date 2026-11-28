import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocara/data/cell.dart';
import 'package:vocara/data/similar_words.dart';
import 'package:vocara/data/word.dart';
import 'package:vocara/features/quiz/quiz.dart';

Word _w(String word) => Word(
  id: 'id-$word',
  word: word,
  meaning: 'm-$word',
  example: '',
  exampleMeaning: '',
);

void main() {
  test('쌍은 어느 쪽에서 물어도 같고, 쌍이 아닌 단어와 자기 자신은 아니다', () {
    expect(areSimilarWords('dad', 'father'), isTrue);
    expect(areSimilarWords('father', 'dad'), isTrue);
    expect(areSimilarWords('dad', 'mother'), isFalse);
    expect(areSimilarWords('dad', 'dad'), isFalse);
    expect(areSimilarWords('apple', 'book'), isFalse);
  });

  test('쌍의 두 단어는 내장 단어의 같은 칸에 있다(단어를 바꾸면 이 목록도 고친다)', () {
    final cellOf = <String, Cell>{};
    for (final cell in Cell.values) {
      final file = File('assets/words/${cell.id}.json');
      for (final row in jsonDecode(file.readAsStringSync()) as List) {
        cellOf[(row as Map)['word'] as String] = cell;
      }
    }
    for (final (a, b) in similarWordPairs) {
      expect(cellOf[a], isNotNull, reason: '$a 이(가) 단어 파일에 없다');
      expect(cellOf[b], cellOf[a], reason: '$a / $b 가 같은 칸에 없다');
    }
  });

  test('시험은 한 문제의 보기 4개에 쌍을 함께 내지 않는다(정답과도, 오답 보기끼리도)', () {
    final words = [
      for (final (a, b) in similarWordPairs) ...[_w(a), _w(b)],
      for (var i = 0; i < 6; i++) _w('filler$i'),
    ];
    for (var seed = 0; seed < 200; seed++) {
      for (final q in buildQuiz(words, Random(seed), length: words.length)) {
        expect(q.options, hasLength(quizOptionCount));
        for (final a in q.options) {
          for (final b in q.options) {
            expect(
              areSimilarWords(a.word, b.word),
              isFalse,
              reason: '씨앗 $seed: ${q.word.word} 문제의 보기에 ${a.word}·${b.word}',
            );
          }
        }
      }
    }
  });

  test('쌍까지 써야 보기 4개가 될 때는 쌍도 보기로 낸다(시험이 끊기지 않게)', () {
    final words = [_w('dad'), _w('father'), _w('apple'), _w('book')];
    final quiz = buildQuiz(words, Random(1));
    expect(quiz, hasLength(4));
    for (final q in quiz) {
      expect(q.options.toSet(), words.toSet());
    }
  });
}
