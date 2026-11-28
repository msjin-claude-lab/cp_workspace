import 'dart:math';

import '../../data/word.dart';

/// 오늘의 단어를 고른다(2026-11-28 사용자 결정). 그날 처음 열 때 한 번 부르고, 고른 것은 하루 동안 고정한다.
///
/// `count`개(단어가 적으면 있는 만큼)를 이 순서로 채운다:
/// 1. 아직 카드로 보지 않은 단어(`lastViewed`에 없는 것) — 그 안에서는 무작위
/// 2. 오답 노트 단어(`wrongIds` 순서, 위에서 이미 고른 것은 건너뛴다)
/// 3. 가장 오래전에 본 단어(`lastViewed` 값이 작은 것부터, 같으면 단어 파일 순서)
List<Word> pickDailyWords({
  required List<Word> words,
  required Map<String, int> lastViewed,
  required List<String> wrongIds,
  required int count,
  required Random random,
}) {
  final total = min(count, words.length);
  if (total <= 0) return const [];

  final unseen = [
    for (final w in words)
      if (!lastViewed.containsKey(w.id)) w,
  ]..shuffle(random);
  final picked = unseen.take(total).toList();
  final pickedIds = {for (final w in picked) w.id};

  final byId = {for (final w in words) w.id: w};
  for (final id in wrongIds) {
    if (picked.length >= total) break;
    final w = byId[id];
    if (w != null && pickedIds.add(id)) picked.add(w);
  }

  if (picked.length < total) {
    final order = {for (var i = 0; i < words.length; i++) words[i].id: i};
    final rest = [
      for (final w in words)
        if (!pickedIds.contains(w.id)) w,
    ];
    rest.sort((a, b) {
      final byTime = (lastViewed[a.id] ?? 0).compareTo(lastViewed[b.id] ?? 0);
      return byTime != 0 ? byTime : order[a.id]!.compareTo(order[b.id]!);
    });
    picked.addAll(rest.take(total - picked.length));
  }
  return picked;
}
