import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/cell_store.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';
import '../common/home_button.dart';
import '../wrong_notes/review_words.dart';

// 화면 구조(2026-11-20 사용자 결정):
// - 학교급 고르기 → 난이도 고르기 → 칸 홈. 선택은 세로 버튼
// - 고른 칸(학교급 + 난이도)은 기기에 남아, 앱을 열면 그 칸 홈으로 바로 간다
// - 칸 홈의 ☰ 메뉴(학교급 ▸ 난이도 2단계)나 "칸 바꾸기"로 칸을 바꾼다
// - 학습·시험·오답 노트 등 안쪽 화면은 ← 뒤로와 ⌂ 홈(칸 홈)을 둔다

/// 앱 첫 화면: 고른 칸이 있으면 칸 홈, 없으면(첫 실행) 학교급 고르기.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(selectedCellProvider);
    return cell.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // 저장된 값을 못 읽으면 처음 실행처럼 다시 고르게 한다
      error: (_, _) => const LevelPickerScreen(),
      data: (value) => value == null
          ? const LevelPickerScreen()
          : CellHomeScreen(cell: value),
    );
  }
}

/// 칸을 고르고 저장한다. 저장에 실패하면 알린다(이번 실행에서는 고른 칸으로 쓴다).
Future<void> _selectCell(BuildContext context, WidgetRef ref, Cell cell) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(selectedCellProvider.notifier).select(cell);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('고른 칸을 저장하지 못했습니다. 다음 실행 때는 전에 저장된 칸으로 시작합니다'),
      ),
    );
  }
}

/// 세로로 쌓는 큰 선택 버튼.
class _PickButton extends StatelessWidget {
  const _PickButton({
    super.key,
    required this.label,
    this.detail,
    required this.onPressed,
  });

  final String label;
  final String? detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.titleLarge)),
            if (detail != null) Text(detail!, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// ① 학교급 고르기. 처음 실행 때는 첫 화면, 그 뒤에는 "칸 바꾸기"로 연다.
class LevelPickerScreen extends StatelessWidget {
  const LevelPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학교급 고르기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final level in SchoolLevel.values)
              _PickButton(
                key: ValueKey('pick-${level.name}'),
                label: level.label,
                onPressed: () => context.push('/pick/${level.name}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// ② 난이도 고르기. 고르면 그 칸을 저장하고 칸 홈으로 간다.
class DifficultyPickerScreen extends ConsumerWidget {
  const DifficultyPickerScreen({super.key, required this.level});

  final SchoolLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${level.label} · 난이도 고르기'),
        actions: const [HomeButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final difficulty in Difficulty.values)
              _DifficultyButton(cell: Cell.of(level, difficulty)),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({required this.cell});

  final Cell cell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(cellWordsProvider(cell));
    return _PickButton(
      key: ValueKey('pick-${cell.id}'),
      label: cell.difficulty.label,
      detail: words.when(
        data: (list) => '${list.length}단어',
        loading: () => '…',
        error: (_, _) => '읽기 실패',
      ),
      onPressed: () async {
        // 이미 칸 홈으로 갔으면(빠른 두 번 누름) 다시 하지 않는다
        if (ModalRoute.of(context)?.isCurrent != true) return;
        final router = GoRouter.of(context);
        await _selectCell(context, ref, cell);
        router.go('/');
      },
    );
  }
}

/// ③ 칸 홈: 고른 칸에서 카드 학습·시험·오답 노트를 연다.
class CellHomeScreen extends ConsumerWidget {
  const CellHomeScreen({super.key, required this.cell});

  final Cell cell;

  /// 안쪽 화면에서 돌아오면 오답 수를 다시 읽는다.
  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    if (ModalRoute.of(context)?.isCurrent != true) return; // 빠른 두 번 누름
    await context.push(path);
    if (context.mounted) ref.invalidate(wrongNotesProvider(cell.level));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final words = ref.watch(cellWordsProvider(cell));
    final wrong = ref.watch(wrongEntriesProvider(cell));
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
        title: Text(cell.label),
      ),
      drawer: _MenuDrawer(current: cell),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              words.when(
                data: (list) => '${list.length}단어',
                loading: () => '…',
                error: (_, _) => '단어를 읽지 못했습니다',
              ),
              key: const ValueKey('home-word-count'),
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: 24),
            _HomeAction(
              key: const ValueKey('home-study'),
              icon: Icons.style,
              label: '카드 학습',
              onPressed: () => _open(context, ref, '/study/${cell.id}'),
            ),
            _HomeAction(
              key: const ValueKey('home-quiz'),
              icon: Icons.quiz,
              label: '4지선다 시험',
              onPressed: () => _open(context, ref, '/quiz/${cell.id}'),
            ),
            _HomeAction(
              key: const ValueKey('home-wrong'),
              icon: Icons.assignment_late_outlined,
              label: wrong.when(
                data: (list) => '오답 노트 · ${list.length}단어',
                loading: () => '오답 노트',
                error: (_, _) => '오답 노트',
              ),
              onPressed: () => _open(context, ref, '/wrong-notes/${cell.id}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('home-change'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('칸 바꾸기'),
              onPressed: () {
                if (ModalRoute.of(context)?.isCurrent != true) return;
                context.push('/pick');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    ),
  );
}

/// ☰ 메뉴: 학교급 ▸ 난이도 2단계로 칸을 바로 바꾼다. 지금 학교급은 펼쳐 둔다.
class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({required this.current});

  final Cell current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '칸 바꾸기',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final level in SchoolLevel.values)
              ExpansionTile(
                key: ValueKey('menu-level-${level.name}'),
                title: Text(level.label),
                initiallyExpanded: level == current.level,
                children: [
                  for (final difficulty in Difficulty.values)
                    _menuCell(context, ref, Cell.of(level, difficulty)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuCell(BuildContext context, WidgetRef ref, Cell cell) {
    final selected = cell == current;
    return ListTile(
      key: ValueKey('menu-cell-${cell.id}'),
      contentPadding: const EdgeInsets.only(left: 40, right: 16),
      title: Text(cell.difficulty.label),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        // 메뉴를 닫는다. pop()은 닫히는 중에 다시 누르면 첫 화면까지 닫으므로 쓰지 않는다
        Scaffold.of(context).closeDrawer();
        if (!selected) _selectCell(context, ref, cell);
      },
    );
  }
}
