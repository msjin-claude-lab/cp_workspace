import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/level_store.dart';
import '../../data/word_repository.dart';

/// 첫 화면(2026-11-20 사용자 결정).
/// - 처음 실행하면 학교급(초등·중등·고등)을 고른다. 고른 값은 기기에 남아 다음 실행에도 쓴다
/// - 고른 학교급의 3칸(하·중·상)만 보인다. 메뉴 아이콘(☰)의 옆 메뉴에서 학교급을 바꾼다
/// - 칸을 누르면 카드 학습·4지선다 시험 중 하나를 고른다
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(selectedLevelProvider);
    return level.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // 저장된 값을 못 읽으면 처음 실행처럼 다시 고르게 한다
      error: (_, _) => const LevelPickerScreen(),
      data: (value) => value == null
          ? const LevelPickerScreen()
          : _CellsScreen(level: value),
    );
  }
}

/// 학교급을 고르고 저장한다. 저장에 실패하면 알린다(이번 실행에서는 고른 값으로 쓴다).
Future<void> _selectLevel(
  BuildContext context,
  WidgetRef ref,
  SchoolLevel level,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(selectedLevelProvider.notifier).select(level);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('학교급을 저장하지 못했습니다. 다음 실행 때는 전에 저장된 학교급으로 시작합니다'),
      ),
    );
  }
}

/// 처음 실행 화면: 학교급 선택.
class LevelPickerScreen extends ConsumerWidget {
  const LevelPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '영단어',
                textAlign: TextAlign.center,
                style: text.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '학교급을 고르세요',
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '나중에 메뉴(☰)에서 바꿀 수 있습니다',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: 32),
              for (final level in SchoolLevel.values) ...[
                FilledButton.tonal(
                  key: ValueKey('pick-${level.name}'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () => _selectLevel(context, ref, level),
                  child: Text(level.label, style: text.titleLarge),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 고른 학교급의 칸 3개.
class _CellsScreen extends ConsumerWidget {
  const _CellsScreen({required this.level});

  final SchoolLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            key: const ValueKey('menu'),
            tooltip: '메뉴',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('영단어 · ${level.label}'),
      ),
      drawer: _MenuDrawer(current: level),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '공부할 칸을 고르세요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final difficulty in Difficulty.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CellTile(cell: Cell.of(level, difficulty)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 옆 메뉴. 지금은 학교급 바꾸기만 있다 — 오답 노트·진도·내 단어장도 여기에 더한다.
class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({required this.current});

  final SchoolLevel current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('학교급', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final level in SchoolLevel.values)
              ListTile(
                key: ValueKey('menu-level-${level.name}'),
                title: Text(level.label),
                selected: level == current,
                trailing: level == current ? const Icon(Icons.check) : null,
                onTap: () {
                  // 메뉴를 닫는다. pop()은 닫히는 중에 다시 누르면 첫 화면까지 닫으므로 쓰지 않는다
                  Scaffold.of(context).closeDrawer();
                  if (level != current) _selectLevel(context, ref, level);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 칸 하나: 난이도와 들어 있는 단어 수. 누르면 카드 학습·시험 중 하나를 고른다.
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
        onTap: () => _chooseMode(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                cell.difficulty.label,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(countText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseMode(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                cell.label,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            ListTile(
              key: const ValueKey('mode-study'),
              leading: const Icon(Icons.style),
              title: const Text('카드 학습'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.push('/study/${cell.id}');
              },
            ),
            ListTile(
              key: const ValueKey('mode-quiz'),
              leading: const Icon(Icons.quiz),
              title: const Text('4지선다 시험'),
              onTap: () {
                Navigator.of(sheet).pop();
                context.push('/quiz/${cell.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
