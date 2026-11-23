import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_info.dart';
import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/study_decks.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';
import '../wrong_notes/review_words.dart';
import 'dialogs.dart';

// 화면 구조(2026-11-22 사용자 결정):
// - 단어장 = 이름 + 학교급 + 난이도. "새 등록"(홈 오른쪽 아래 동그란 버튼)은 무조건 새 단어장을 만든다:
//   이름 입력 → 학교급 고르기 → 난이도 고르기. 같은 학교급+난이도도 여러 개 만들 수 있고
//   학습 기록·오답 노트·진도는 단어장마다 따로 쌓인다
// - 고른 단어장은 기기에 남아, 앱을 열면 그 단어장 홈으로 바로 간다. 단어장이 없으면 시작 화면
// - ☰ 메뉴에는 내 단어장만(이름, ✓ 지금 것, ⋮ 이름 바꾸기·지우기). "메인화면"·"기본 단어장"은
//   메뉴에 없다
// - 학습·시험·오답 노트 등 안쪽 화면은 위쪽 ← 뒤로로 돌아온다(따로 "홈으로" 버튼은 두지 않는다)
//   ("칸"은 개발용 말 — 화면에는 쓰지 않는다. 제목은 `<단어장 이름> - 시험` 꼴)

/// 앱 첫 화면: 고른 단어장이 있으면 그 홈, 단어장이 하나도 없으면 시작 화면.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deckListProvider);
    return list.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('단어장을 읽지 못했습니다'),
              const SizedBox(height: 16),
              // 다시 읽는 동안은 위 loading 분기의 진행 표시가 보인다
              FilledButton(
                key: const ValueKey('home-retry'),
                onPressed: () => ref.invalidate(deckListProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      data: (value) => switch (value.current) {
        final deck? => DeckHomeScreen(deck: deck),
        null => const StartScreen(),
      },
    );
  }
}

/// 새 단어장 만들기를 시작한다: 이름을 받고 학교급 고르기로 간다.
/// 어느 단계에서든 취소·← 뒤로면 아무것도 만들지 않는다 — 만드는 것은 난이도를 고를 때다.
Future<void> startCreateDeck(BuildContext context) async {
  if (ModalRoute.of(context)?.isCurrent != true) return; // 빠른 두 번 누름
  final router = GoRouter.of(context);
  final name = await showDeckNameDialog(
    context,
    title: '새 단어장',
    confirmLabel: '다음', // 이름 다음에 학교급·난이도를 고른다. 이름 바꾸기는 '저장'
  );
  if (name == null) return;
  router.push(Uri(path: '/pick', queryParameters: {'name': name}).toString());
}

/// 고른 것 저장에 실패했을 때 알린다(이번 실행에서는 고른 단어장으로 쓴다).
void _showNotSaved(ScaffoldMessengerState messenger) => messenger.showSnackBar(
  const SnackBar(
    content: Text('고른 단어장을 저장하지 못했습니다. 다음 실행 때는 전에 고른 단어장으로 시작합니다'),
  ),
);

/// 단어장이 하나도 없을 때(처음 실행, 모두 지웠을 때): 앱 제목과 첫 단어장 만들기 버튼.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '단어장을 만들어 공부를 시작하세요',
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('start-create'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 32,
                    ),
                    textStyle: text.titleMedium,
                  ),
                  icon: const Icon(Icons.edit_square),
                  label: const Text('새 단어장 만들기'),
                  onPressed: () => startCreateDeck(context),
                ),
              ],
            ),
          ),
        ),
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

/// 선택 버튼들 위에 두는 안내 문구.
class _Guide extends StatelessWidget {
  const _Guide(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// 새 단어장 고르기 화면의 제목 `새 단어장 - <이름>`. 이름이 길면 줄임표로 줄인다.
class _NewDeckTitle extends StatelessWidget {
  const _NewDeckTitle(this.name);

  final String name;

  @override
  Widget build(BuildContext context) =>
      Text('새 단어장 - $name', maxLines: 1, overflow: TextOverflow.ellipsis);
}

/// 새 단어장 ② 학교급 고르기(① 이름은 창으로 받았다). 홈 위에 쌓아 ← 뒤로로 그만둘 수 있다.
class LevelPickerScreen extends StatelessWidget {
  const LevelPickerScreen({super.key, required this.name});

  /// 만들 단어장 이름.
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 제목은 만들고 있는 단어장 이름, 할 일은 버튼 위 안내 문구로
      // (2026-11-22 사용자 결정(UX 점검) — 두 고르기 화면이 같은 제목으로 한 흐름임을 보인다)
      appBar: AppBar(title: _NewDeckTitle(name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _Guide('학교급을 고르세요'),
            for (final level in SchoolLevel.values)
              _PickButton(
                key: ValueKey('pick-${level.name}'),
                label: level.label,
                onPressed: () => context.push(
                  Uri(
                    path: '/pick/${level.name}',
                    queryParameters: {'name': name},
                  ).toString(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 새 단어장 ③ 난이도 고르기. 고르면 단어장을 만들고 고른 뒤 그 홈으로 간다.
class DifficultyPickerScreen extends ConsumerStatefulWidget {
  const DifficultyPickerScreen({
    super.key,
    required this.level,
    required this.name,
  });

  final SchoolLevel level;
  final String name;

  @override
  ConsumerState<DifficultyPickerScreen> createState() =>
      _DifficultyPickerScreenState();
}

class _DifficultyPickerScreenState
    extends ConsumerState<DifficultyPickerScreen> {
  /// 만드는 중. 빠르게 두 번 누르면 단어장이 둘 생기므로 한 번만 만든다.
  bool _creating = false;

  Future<void> _create(Cell cell) async {
    if (_creating || ModalRoute.of(context)?.isCurrent != true) return;
    _creating = true;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final decks = ref.read(deckListProvider.notifier);
    try {
      await decks.create(widget.name, cell);
    } on DeckSelectionNotSaved {
      _showNotSaved(messenger);
    } catch (_) {
      _creating = false;
      messenger.showSnackBar(const SnackBar(content: Text('단어장을 만들지 못했습니다')));
      return;
    }
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _NewDeckTitle(widget.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _Guide('난이도를 고르세요'),
            for (final difficulty in Difficulty.values)
              _DifficultyButton(
                cell: Cell.of(widget.level, difficulty),
                onPressed: _create,
              ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({required this.cell, required this.onPressed});

  final Cell cell;
  final void Function(Cell cell) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(cellWordsProvider(cell));
    return _PickButton(
      key: ValueKey('pick-${cell.id}'),
      label: cell.difficulty.label,
      detail: words.when(
        data: (list) => '${list.length}단어',
        loading: () => '…',
        error: (_, _) => '읽지 못했습니다',
      ),
      onPressed: () => onPressed(cell),
    );
  }
}

/// 단어장 홈: 고른 단어장에서 카드 학습·시험·오답 노트·진도를 연다.
class DeckHomeScreen extends ConsumerWidget {
  const DeckHomeScreen({super.key, required this.deck});

  final StudyDeck deck;

  /// 안쪽 화면에서 돌아오면 오답 수를 다시 읽는다.
  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    if (ModalRoute.of(context)?.isCurrent != true) return; // 빠른 두 번 누름
    await context.push(path);
    if (context.mounted) ref.invalidate(deckWrongNotesProvider(deck));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final words = ref.watch(deckWordsProvider(deck));
    final wrong = ref.watch(wrongEntriesProvider(deck));
    // 한 번에 하는 카드 수·문항 수(설정). 읽는 동안이나 읽지 못하면 단어 수만 보인다
    final settings = ref.watch(deckSettingsProvider(deck)).value;
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
        title: Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      drawer: _MenuDrawer(current: deck),
      // 오른쪽 아래 동그란 버튼(글쓰기 아이콘): 새 등록 — 무조건 새 단어장을 만든다(2026-11-22 사용자 결정).
      // 고르는 화면은 홈 위에 쌓아 ← 뒤로로 그만둘 수 있다
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('home-register'),
        tooltip: '새 등록',
        shape: const CircleBorder(),
        onPressed: () => startCreateDeck(context),
        child: const Icon(Icons.edit_square),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 단어장 이름 아래에 바탕 학교급·난이도(예: 중등 [난이도 : 중간])
            Text(
              deck.base.label,
              key: const ValueKey('home-base'),
              textAlign: TextAlign.center,
              // 아래 두 줄(단어 수, 카드 수·문항 수 — 16)보다 크고 위의 단어장 이름(앱바 제목 — 22)보다
              // 작게(2026-11-23 사용자 결정)
              style: text.titleMedium?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 4),
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
            // 셋째 줄: 한 번에 하는 카드 수·문항 수(2026-11-23 사용자 결정).
            // 설정이 단어 수보다 크면 실제로 나오는 수(있는 만큼)를 보인다
            if (settings != null && words.hasValue) ...[
              const SizedBox(height: 4),
              Text(
                '한 번에 카드 ${min(settings.cardCount, words.requireValue.length)}장'
                ' · 시험 ${min(settings.quizCount, words.requireValue.length)}문제',
                key: const ValueKey('home-counts'),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ],
            const SizedBox(height: 24),
            _HomeAction(
              key: const ValueKey('home-study'),
              icon: Icons.style,
              label: '카드 학습',
              onPressed: () => _open(context, ref, '/study/${deck.id}'),
            ),
            _HomeAction(
              key: const ValueKey('home-quiz'),
              icon: Icons.edit_note, // 종이와 연필(사용자: 물음표 아이콘은 어색)
              label: '시험',
              onPressed: () => _open(context, ref, '/quiz/${deck.id}'),
            ),
            _HomeAction(
              key: const ValueKey('home-wrong'),
              icon: Icons.assignment_late_outlined,
              label: wrong.when(
                data: (list) => '오답 노트 · ${list.length}단어',
                loading: () => '오답 노트',
                error: (_, _) => '오답 노트',
              ),
              onPressed: () => _open(context, ref, '/wrong-notes/${deck.id}'),
            ),
            _HomeAction(
              key: const ValueKey('home-progress'),
              icon: Icons.bar_chart,
              label: '진도',
              onPressed: () => _open(context, ref, '/progress/${deck.id}'),
            ),
            // 진도 바로 아래(2026-11-22 사용자 결정): 이 단어장의 카드 학습 단어 수·시험 문항 수
            _HomeAction(
              key: const ValueKey('home-settings'),
              icon: Icons.settings,
              label: '설정',
              onPressed: () => _open(context, ref, '/settings/${deck.id}'),
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

/// ☰ 메뉴: 앱 제목·버전과 **내 단어장만**(2026-11-22 사용자 결정 — 이름, 아래에 학교급·난이도).
/// 누르면 그것이 홈이 되고 저장된다. ⋮로 이름 바꾸기·지우기. 만들기는 홈 오른쪽 아래 동그란 버튼.
/// "메인화면" 버튼·"기본 단어장" 목록은 두지 않는다.
class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({required this.current});

  /// 지금 홈인 단어장.
  final StudyDeck current;

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    StudyDeck deck,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final decks = ref.read(deckListProvider.notifier);
    final name = await showDeckNameDialog(
      context,
      initial: deck.name,
      title: '이름 바꾸기',
    );
    if (name == null || name == deck.name) return;
    try {
      await decks.rename(deck, name);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('이름을 바꾸지 못했습니다')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    StudyDeck deck,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final decks = ref.read(deckListProvider.notifier);
    final ok = await confirmDelete(
      context,
      // 무엇을 잃는지 밝힌다(2026-11-22 사용자 결정(UX 점검)). 그 단어장의 오답 노트·학습·시험 기록은 DB에서 함께 지운다
      title: '"${deck.name}" 단어장을 지울까요?',
      message: '이 단어장의 오답 노트와 진도 기록이 사라지고 되돌릴 수 없습니다',
    );
    if (!ok) return;
    try {
      await decks.delete(deck);
    } on DeckSelectionNotSaved {
      _showNotSaved(messenger);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('단어장을 지우지 못했습니다')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 못 읽으면 지금 단어장만이라도 보여 준다
    final listed = ref.watch(deckListProvider).value?.decks ?? const [];
    final decks = listed.contains(current) ? listed : [...listed, current];
    return Drawer(
      child: SafeArea(
        // 위: 제목·버전(고정) / 가운데: 단어장 목록(이 부분만 스크롤) / 아래: 앱 정보(고정)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              // 앱 제목 + 작은 글씨의 버전. 예: 영단어 v1.0.0
              child: Text.rich(
                key: const ValueKey('menu-title'),
                TextSpan(
                  text: appTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  children: [
                    TextSpan(
                      text: ' v$appVersion',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const ValueKey('menu-decks'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final deck in decks)
                    ListTile(
                      key: ValueKey('menu-deck-${deck.deckId}'),
                      // 긴 이름은 두 줄까지 보이고 그 뒤는 줄임표
                      title: Text(
                        deck.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(deck.base.label),
                      selected: deck == current,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (deck == current) const Icon(Icons.check),
                          PopupMenuButton<String>(
                            key: ValueKey('menu-deck-more-${deck.deckId}'),
                            tooltip: '더 보기',
                            onSelected: (action) => action == 'rename'
                                ? _rename(context, ref, deck)
                                : _delete(context, ref, deck),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                key: ValueKey('deck-rename'),
                                value: 'rename',
                                child: Text('이름 바꾸기'),
                              ),
                              PopupMenuItem(
                                key: ValueKey('deck-delete'),
                                value: 'delete',
                                child: Text('지우기'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        // 메뉴를 닫는다. pop()은 닫히는 중에 다시 누르면 첫 화면까지 닫으므로 쓰지 않는다
                        Scaffold.of(context).closeDrawer();
                        if (deck != current) _select(context, ref, deck);
                      },
                    ),
                ],
              ),
            ),
            // 메뉴 맨 아래 고정: 앱 정보(버전·오픈소스 라이선스, 나중에 단어 출처) — 2026-11-23 사용자 결정
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('menu-about'),
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 정보'),
              onTap: () {
                // 빠른 두 번 누름에 두 번 열리지 않게
                if (ModalRoute.of(context)?.isCurrent != true) return;
                final router = GoRouter.of(context);
                Scaffold.of(context).closeDrawer();
                router.push('/about');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    StudyDeck deck,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deckListProvider.notifier).select(deck);
    } on DeckSelectionNotSaved {
      _showNotSaved(messenger);
    }
  }
}

/// 주소의 `deck_<번호>`로 이름 있는 단어장을 찾아 화면을 만든다. 없으면(지워졌으면) 안내만 보인다.
class StudyDeckLoader extends ConsumerWidget {
  const StudyDeckLoader({
    super.key,
    required this.deckId,
    required this.builder,
  });

  final int deckId;
  final Widget Function(StudyDeck deck) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deckListProvider);
    const missing = Scaffold(body: Center(child: Text('찾을 수 없는 화면입니다')));
    return list.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => missing,
      data: (value) {
        for (final deck in value.decks) {
          if (deck.deckId == deckId) return builder(deck);
        }
        return missing;
      },
    );
  }
}
