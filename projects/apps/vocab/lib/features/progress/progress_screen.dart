import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';
import 'progress_calendar.dart';

/// 진도(홈 → 진도): **지금 고른 학교급·난이도 하나의 진도만** 보여 준다(2026-11-22 사용자 결정 —
/// 전에는 9개를 모두 보여 줬다). 맨 위 "진행 N일차"(이 난이도를 처음 공부한 날이 1일차),
/// 외운 수/전체·오답 수, 날짜별 기록 달력(`progress_calendar.dart`).
/// 외웠다 = 그 단어의 마지막 시험 답이 맞힘(명세).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.cell});

  final Cell cell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(cell));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('${cell.label} - 진도')),
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
                _Summary(
                  cell: cell,
                  memorized: p.memorized[cell] ?? 0,
                  wrong: p.wrong[cell] ?? 0,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
                  child: Text('날짜별 기록', style: text.titleMedium),
                ),
                ProgressCalendar(days: p.days, today: DateTime.now()),
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
    required this.cell,
    required this.memorized,
    required this.wrong,
  });

  final Cell cell;
  final int memorized;
  final int wrong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(cellWordsProvider(cell)).value?.length ?? 0;
    // 단어 파일에서 빠진 단어의 기록이 남아 있어도 전체를 넘지 않게 한다
    final done = memorized > total ? total : memorized;
    return Padding(
      key: const ValueKey('progress-summary'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '외움 $done/$total · 오답 $wrong',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: total == 0 ? 0 : done / total),
        ],
      ),
    );
  }
}
