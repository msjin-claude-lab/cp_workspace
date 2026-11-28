import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/study_decks.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';
import 'daily_pick.dart';

/// 오늘의 단어에서 안 본 단어를 섞는 난수. 시험 섞기(`quizRandomProvider`)와 따로 둔다 — 홈이 오늘의
/// 단어를 고르느라 시험 문제 순서가 바뀌지 않게. 시험에서는 씨앗을 고정한 Random을 넣는다.
final dailyRandomProvider = Provider<Random>((ref) => Random());

/// 단어장 하나의 오늘의 단어: 그날 고른 단어(순서 그대로)와 그중 본 것.
class TodayWords {
  const TodayWords({
    required this.day,
    required this.words,
    required this.seenIds,
  });

  /// 고른 날(`dayKey`). 화면을 연 채 자정을 넘겨도 본 것은 이 날의 묶음에 남긴다.
  final String day;
  final List<Word> words;
  final Set<String> seenIds;

  int get total => words.length;

  int get seen => words.where((w) => seenIds.contains(w.id)).length;

  /// 고른 단어를 모두 카드로 봤다(2026-11-28 사용자 결정 — 시험 없이 카드만).
  bool get completed => words.isNotEmpty && seen == words.length;
}

/// 그 단어장의 오늘의 단어. 그날 처음 읽을 때 [pickDailyWords]로 고르고 저장해, 같은 날에는 앱을
/// 다시 시작해도 같은 단어가 같은 순서로 나온다. 날짜는 [nowProvider]의 기기 시각 자정에 바뀐다.
/// 개수 설정을 바꾸면 다음에 고를 때(다음 날)부터 쓴다.
final todayWordsProvider = FutureProvider.autoDispose
    .family<TodayWords, StudyDeck>((ref, deck) async {
      final day = dayKey(ref.watch(nowProvider)());
      final decks = ref.watch(studyDecksProvider);
      final records = ref.watch(studyRecordsProvider);
      final random = ref.watch(dailyRandomProvider);
      final wordsFuture = ref.watch(deckWordsProvider(deck).future);
      final settingsFuture = ref.watch(deckSettingsProvider(deck).future);
      final words = await wordsFuture;
      final settings = await settingsFuture;

      var set = await decks.loadDailySet(deck.deckId, day);
      if (set == null) {
        final picked = pickDailyWords(
          words: words,
          lastViewed: await records.lastViewedTimes(deck),
          wrongIds: [
            for (final note in await records.deckWrongNotes(deck)) note.wordId,
          ],
          count: settings.dailyCount,
          random: random,
        );
        set = await decks.createDailySet(deck.deckId, day, [
          for (final w in picked) w.id,
        ]);
      }
      final byId = {for (final w in words) w.id: w};
      return TodayWords(
        day: set.day,
        // 단어 파일에서 빠진 단어는 건너뛴다
        words: [for (final id in set.wordIds) ?byId[id]],
        seenIds: set.seenIds,
      );
    });
