import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/word_repository.dart';

/// 첫 화면: 학교급(행) × 난이도(열) 9칸에서 공부할 칸을 고른다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영단어')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('공부할 칸을 고르세요',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              for (final level in SchoolLevel.values) ...[
                _LevelRow(level: level),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level});

  final SchoolLevel level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(level.label,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final difficulty in Difficulty.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CellTile(cell: Cell.of(level, difficulty)),
            ),
          ),
      ],
    );
  }
}

/// 칸 하나: 난이도와 들어 있는 단어 수. 누르면 그 칸의 카드 학습으로 간다.
class CellTile extends ConsumerWidget {
  const CellTile({super.key, required this.cell});

  final Cell cell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(cellWordsProvider(cell));
    final countText = words.when(
      data: (list) => '${list.length}단어',
      loading: () => '…',
      error: (_, _) => '읽기 실패',
    );
    return Card(
      key: ValueKey('cell-${cell.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/study/${cell.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(cell.difficulty.label,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(countText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
