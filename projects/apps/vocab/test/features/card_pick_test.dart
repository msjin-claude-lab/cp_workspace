import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/features/study/card_pick.dart';

import '../fakes.dart' show NoShuffleRandom;

List<Word> _words(int n) => [
  for (var i = 0; i < n; i++)
    Word(id: 'w$i', word: 'word$i', meaning: 'm$i', example: '', exampleMeaning: ''),
];

void main() {
  test('설정한 수만큼, 같은 단어 없이 고른다(단어가 적으면 있는 만큼)', () {
    final words = _words(267);
    final picked = pickCards(words, const {}, 50, Random(1));
    expect(picked, hasLength(50));
    expect(picked.map((w) => w.id).toSet(), hasLength(50));

    expect(pickCards(_words(7), const {}, 50, Random(1)), hasLength(7));
    expect(pickCards(const [], const {}, 50, Random(1)), isEmpty);
    expect(pickCards(words, const {}, 0, Random(1)), isEmpty);
  });

  test('80%는 안 본 단어에서 나온다 — 본 단어는 많아야 전체 무작위 몫(20%)만큼', () {
    final words = _words(267);
    // 앞의 200개를 이미 봤다 → 안 본 단어 67개
    final seen = {for (final w in words.take(200)) w.id};
    for (var seed = 0; seed < 100; seed++) {
      final picked = pickCards(words, seen, 50, Random(seed));
      final seenPicked = picked.where((w) => seen.contains(w.id)).length;
      expect(seenPicked, lessThanOrEqualTo(10), reason: '씨앗 $seed');
      expect(picked.map((w) => w.id).toSet(), hasLength(50));
    }
  });

  test('안 본 단어가 80% 몫보다 적으면 안 본 단어는 모두 나오고 나머지는 본 단어로 채운다', () {
    final words = _words(100);
    final unseenIds = {'w3', 'w50', 'w99'};
    final seen = {
      for (final w in words)
        if (!unseenIds.contains(w.id)) w.id,
    };
    for (var seed = 0; seed < 50; seed++) {
      final picked = pickCards(words, seen, 50, Random(seed));
      expect(picked, hasLength(50));
      expect(picked.map((w) => w.id).toSet(), containsAll(unseenIds));
    }
  });

  test('회차마다 안 본 단어를 먼저 내므로 267단어·50장이면 7회차 안에 모두 한 번씩 본다', () {
    final words = _words(267);
    final random = Random(7);
    final seen = <String>{};
    for (var round = 0; round < 7; round++) {
      seen.addAll(pickCards(words, seen, 50, random).map((w) => w.id));
    }
    expect(seen, hasLength(267));
  });

  test('모두 본 뒤에도 설정한 수만큼 무작위로 낸다', () {
    final words = _words(30);
    final seen = {for (final w in words) w.id};
    final a = pickCards(words, seen, 10, Random(1));
    final b = pickCards(words, seen, 10, Random(2));
    expect(a, hasLength(10));
    expect(a.map((w) => w.id), isNot(b.map((w) => w.id)));
  });

  test('카드가 1~2장이면 전체 무작위 몫 없이 안 본 단어만 낸다', () {
    final words = _words(10);
    final seen = {for (final w in words.take(8)) w.id};
    for (var seed = 0; seed < 30; seed++) {
      expect(
        pickCards(words, seen, 2, Random(seed)).map((w) => w.id).toSet(),
        {'w8', 'w9'},
      );
    }
  });

  test('섞지 않는 난수를 넣으면 저장된 순서대로 나온다(화면 시험이 순서를 정해 둘 수 있게)', () {
    final words = _words(12);
    expect(pickCards(words, const {}, 12, NoShuffleRandom()), words);
  });
}
