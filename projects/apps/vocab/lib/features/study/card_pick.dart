import 'dart:math';

import '../../data/word.dart';

/// 한 회차 카드 중 "전체에서 무작위"로 뽑는 몫. 나머지는 안 본 단어를 먼저 뽑는다.
const double randomCardShare = 0.2;

/// 카드 학습 한 회차에 낼 카드를 고른다(2026-11-23 사용자 결정 — 전에는 전체에서 무작위라
/// 단어가 많은 단어장은 끝까지 안 나오는 단어가 있을 수 있었다).
///
/// - `count`장(단어가 적으면 있는 만큼) 중 20%([randomCardShare], 반올림)는 **전체에서 무작위**
/// - 나머지 80%는 그 20%에 든 단어를 빼고 **아직 카드로 보지 않은 단어(`seenIds`에 없는 것)를
///   먼저** 무작위로 뽑는다. 안 본 단어가 모자라면 본 단어에서 무작위로 채운다
/// - 고른 카드는 한 번 더 섞어 두 묶음이 섞여 나오게 한다
///
/// 기본 50장·267단어면 한 회차에 새 단어가 40장 이상이라 7회차 안에 모두 한 번씩 본다.
List<Word> pickCards(
  List<Word> words,
  Set<String> seenIds,
  int count,
  Random random,
) {
  final total = min(count, words.length);
  if (total <= 0) return const [];
  final randomCount = (total * randomCardShare).round();
  final picked = ([...words]..shuffle(random)).take(randomCount).toList();
  final pickedIds = {for (final w in picked) w.id};

  final rest = [
    for (final w in words)
      if (!pickedIds.contains(w.id)) w,
  ];
  final unseen = [
    for (final w in rest)
      if (!seenIds.contains(w.id)) w,
  ]..shuffle(random);
  final seen = [
    for (final w in rest)
      if (seenIds.contains(w.id)) w,
  ]..shuffle(random);

  picked.addAll([...unseen, ...seen].take(total - randomCount));
  return picked..shuffle(random);
}
