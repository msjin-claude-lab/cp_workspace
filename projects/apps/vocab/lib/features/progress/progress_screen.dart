import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';

/// 진도(홈 → 진도): 연속 학습일, 난이도별 외운 수/전체·오답 수(학교급마다 쉬움·중간·어려움),
/// 날짜별 공부 수·맞힌 수(2026-11-20 사용자 결정 — 진도는 난이도별로, 전체 9단계 + 날짜별).
/// 외웠다 = 그 단어의 마지막 시험 답이 맞힘(명세).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, this.current});

  /// 지금 고른 학교급·난이도. 그 줄을 강조한다.
  final Cell? current;

  /// 날짜별 목록에 보여 줄 날 수.
  static const int shownDays = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('진도')),
      body: SafeArea(
        child: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('진도를 읽지 못했습니다')),
          data: (p) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '연속 학습 ${p.streak(DateTime.now())}일',
                    key: const ValueKey('progress-streak'),
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                ),
              ),
              for (final level in SchoolLevel.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
                  child: Text(level.label, style: text.titleMedium),
                ),
                for (final difficulty in Difficulty.values)
                  _CellRow(
                    cell: Cell.of(level, difficulty),
                    memorized: p.memorized[Cell.of(level, difficulty)] ?? 0,
                    wrong: p.wrong[Cell.of(level, difficulty)] ?? 0,
                    highlighted: Cell.of(level, difficulty) == current,
                  ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
                child: Text('날짜별 기록', style: text.titleMedium),
              ),
              if (p.days.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('아직 공부한 기록이 없습니다', style: text.bodyMedium),
                )
              else
                for (final d in p.days.take(shownDays))
                  ListTile(
                    key: ValueKey('progress-day-${d.day}'),
                    dense: true,
                    title: Text(d.day),
                    trailing: Text(
                      '공부 ${d.studied} · 시험 맞힘 ${d.correct}',
                      style: text.bodyMedium,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 난이도 한 줄: 외운 수/전체 막대와 오답 수.
class _CellRow extends ConsumerWidget {
  const _CellRow({
    required this.cell,
    required this.memorized,
    required this.wrong,
    required this.highlighted,
  });

  final Cell cell;
  final int memorized;
  final int wrong;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(cellWordsProvider(cell)).value?.length ?? 0;
    // 단어 파일에서 빠진 단어의 기록이 남아 있어도 전체를 넘지 않게 한다
    final done = memorized > total ? total : memorized;
    return Container(
      key: ValueKey('progress-${cell.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? theme.colorScheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cell.difficulty.label,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '외움 $done/$total · 오답 $wrong',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: total == 0 ? 0 : done / total),
        ],
      ),
    );
  }
}
