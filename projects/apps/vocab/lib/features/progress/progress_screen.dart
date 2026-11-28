import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_decks.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';
import '../ads/banner_ad.dart';
import 'progress_calendar.dart';

/// 진도(홈 → 진도): **지금 고른 단어장 하나의 진도만** 보여 준다(2026-11-22 사용자 결정 —
/// 같은 학교급+난이도로 만든 다른 단어장의 기록도 섞지 않는다). 맨 위 "진행 N일차"(이 단어장을
/// 처음 공부한 날이 1일차), 외운 수/전체·오답 수, 날짜별 기록 달력(`progress_calendar.dart`).
/// 외웠다 = 이 단어장에서 그 단어의 마지막 시험 답이 맞힘(명세).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(deck));
    // 오늘의 단어를 끝낸 날. 읽는 중이거나 읽지 못하면 표시 없이
    final dailyDone =
        ref.watch(dailyCompletedDaysProvider(deck)).value ?? const <String>{};
    final text = Theme.of(context).textTheme;
    return Scaffold(
      bottomNavigationBar: const BottomBanner(), // 광고 배너(불러온 뒤에만 자리가 생긴다)
      appBar: AppBar(
        title: Text(
          '${deck.label} - 진도',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('진도를 읽지 못했습니다')),
          data: (p) {
            final day = p.elapsedDays(DateTime.now());
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      day == 0 ? '아직 시작하지 않았습니다' : '진행 $day일차',
                      key: const ValueKey('progress-days'),
                      textAlign: TextAlign.center,
                      style: text.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Summary(deck: deck, memorized: p.memorized, wrong: p.wrong),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
                  child: Text('날짜별 기록', style: text.titleMedium),
                ),
                ProgressCalendar(
                  days: p.days,
                  today: DateTime.now(),
                  dailyDone: dailyDone,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 외운 수/전체 막대와 오답 수.
class _Summary extends ConsumerWidget {
  const _Summary({
    required this.deck,
    required this.memorized,
    required this.wrong,
  });

  final Deck deck;
  final int memorized;
  final int wrong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(deckWordsProvider(deck)).value?.length ?? 0;
    // 단어 파일에서 빠진 단어의 기록이 남아 있어도 전체를 넘지 않게 한다
    final done = memorized > total ? total : memorized;
    return Padding(
      key: const ValueKey('progress-summary'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '외운 단어 $done/$total',
            key: const ValueKey('progress-memorized'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          // "외웠다"의 뜻을 밝힌다(2026-11-22 사용자 결정(UX 점검) — 숫자가 무엇인지 모르겠다는 지적)
          Text(
            '시험에서 맞힌 단어를 외운 것으로 셉니다',
            key: const ValueKey('progress-caption'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: total == 0 ? 0 : done / total),
          const SizedBox(height: 12),
          Text(
            '오답 노트 $wrong단어',
            key: const ValueKey('progress-wrong'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
