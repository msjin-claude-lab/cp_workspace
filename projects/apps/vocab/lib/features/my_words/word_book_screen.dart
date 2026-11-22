import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_books.dart';
import '../quiz/quiz.dart';
import '../wrong_notes/review_words.dart';
import 'dialogs.dart';

/// 내 단어장 하나(내 단어장 → 단어장): 카드 학습·시험·오답 노트를 열고, 단어를 더하거나 고치거나 지운다.
/// 제목은 단어장 이름. 카드 학습·시험·오답 노트 화면은 칸과 같은 화면을 쓴다([Deck]).
/// 시험은 단어가 4개 이상일 때만(명세).
class WordBookScreen extends ConsumerStatefulWidget {
  const WordBookScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<WordBookScreen> createState() => _WordBookScreenState();
}

class _WordBookScreenState extends ConsumerState<WordBookScreen> {
  /// 저장 중. 이때는 추가·고치기·지우기를 다시 받지 않는다(두 번 저장 막기).
  bool _busy = false;

  /// 창을 띄우거나 화면을 열어도 되나 — 이미 위에 무엇이 있으면(빠른 두 번 누름) 아무것도 하지 않는다.
  bool get _ready => !_busy && ModalRoute.of(context)?.isCurrent == true;

  /// 안쪽 화면(카드 학습·시험·오답 노트)에서 돌아오면 오답 수를 다시 읽는다.
  Future<void> _open(BookDeck deck, String path) async {
    if (!_ready) return;
    await context.push(path);
    if (mounted) ref.invalidate(deckWrongNotesProvider(deck));
  }

  /// DB 작업을 하고 단어·오답 노트를 다시 읽는다. 실패하면 알린다.
  Future<void> _run(
    BookDeck deck,
    Future<void> Function() work,
    String failMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await work();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failMessage)));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(bookWordsProvider(widget.bookId));
    ref.invalidate(deckWrongNotesProvider(deck));
  }

  Future<void> _add(BookDeck deck) async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final input = await showWordForm(context);
    if (input == null || !mounted) return;
    await _run(
      deck,
      () => books.addWord(
        widget.bookId,
        word: input.word,
        meaning: input.meaning,
        example: input.example,
        exampleMeaning: input.exampleMeaning,
      ),
      '단어를 저장하지 못했습니다',
    );
  }

  Future<void> _edit(BookDeck deck, Word word) async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final input = await showWordForm(context, initial: word);
    if (input == null || !mounted) return;
    await _run(
      deck,
      () => books.updateWord(
        Word(
          id: word.id,
          word: input.word,
          meaning: input.meaning,
          example: input.example,
          exampleMeaning: input.exampleMeaning,
        ),
      ),
      '단어를 저장하지 못했습니다',
    );
  }

  Future<void> _delete(BookDeck deck, Word word) async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final ok = await confirmDelete(
      context,
      title: '${word.word} 단어를 지울까요?',
      message: '이 단어의 오답 노트도 함께 지워집니다',
    );
    if (!ok || !mounted) return;
    await _run(deck, () => books.deleteWord(word.id), '단어를 지우지 못했습니다');
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(wordBookProvider(widget.bookId));
    return switch (book) {
      AsyncData(value: null) => const MissingBookScreen(),
      AsyncData(value: final b?) => _screen(b.deck),
      AsyncError() => const Scaffold(
        body: Center(child: Text('단어장을 읽지 못했습니다')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  Widget _screen(BookDeck deck) {
    final text = Theme.of(context).textTheme;
    final words = ref.watch(bookWordsProvider(widget.bookId));
    final wrong = ref.watch(wrongEntriesProvider(deck));
    final list = words.value ?? const <Word>[];
    // 단어가 4개 미만이거나 영단어·뜻이 겹쳐 보기 4개를 만들 수 없으면 시험을 막고 까닭을 보여 준다
    final quizBlocked = quizBlockReason(list);
    final canQuiz = quizBlocked == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('book-add-word'),
        icon: const Icon(Icons.add),
        label: const Text('단어 추가'),
        onPressed: _busy ? null : () => _add(deck),
      ),
      body: SafeArea(
        child: words.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('단어를 읽지 못했습니다')),
          data: (_) => ListView(
            // 아래 추가 버튼이 마지막 줄을 가리지 않게 띄운다
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
            children: [
              Text(
                '${list.length}단어',
                key: const ValueKey('book-word-count'),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: 24),
              _BookAction(
                key: const ValueKey('book-study'),
                icon: Icons.style,
                label: '카드 학습',
                onPressed: list.isEmpty
                    ? null
                    : () => _open(deck, '/study/${deck.id}'),
              ),
              _BookAction(
                key: const ValueKey('book-quiz'),
                icon: Icons.edit_note,
                label: '시험',
                onPressed: canQuiz
                    ? () => _open(deck, '/quiz/${deck.id}')
                    : null,
              ),
              if (!canQuiz)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    quizBlocked,
                    key: const ValueKey('book-quiz-locked'),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                ),
              _BookAction(
                key: const ValueKey('book-wrong'),
                icon: Icons.assignment_late_outlined,
                label: wrong.when(
                  data: (l) => '오답 노트 · ${l.length}단어',
                  loading: () => '오답 노트',
                  error: (_, _) => '오답 노트',
                ),
                onPressed: () => _open(deck, '/wrong-notes/${deck.id}'),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  key: ValueKey('book-empty'),
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '아직 단어가 없습니다.\n아래 "단어 추가"로 넣어 보세요',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final w in list)
                ListTile(
                  key: ValueKey('book-word-${w.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(w.word),
                  subtitle: Text(w.meaning),
                  onTap: _busy ? null : () => _edit(deck, w),
                  trailing: IconButton(
                    key: ValueKey('book-word-delete-${w.id}'),
                    tooltip: '단어 지우기',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _busy ? null : () => _delete(deck, w),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 단어장 화면의 큰 버튼. `onPressed`가 null이면 막힌다(단어가 모자랄 때).
class _BookAction extends StatelessWidget {
  const _BookAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

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

/// 주소의 단어장 번호로 이름을 읽은 뒤 카드 학습·시험·오답 노트 화면을 만든다.
/// 단어장이 없으면(지워졌으면) 안내만 보인다.
class BookDeckLoader extends ConsumerWidget {
  const BookDeckLoader({
    super.key,
    required this.bookId,
    required this.builder,
  });

  final int bookId;
  final Widget Function(Deck deck) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(wordBookProvider(bookId))) {
      AsyncData(value: null) => const MissingBookScreen(),
      AsyncData(value: final b?) => builder(b.deck),
      AsyncError() => const Scaffold(
        body: Center(child: Text('단어장을 읽지 못했습니다')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

/// 없는(지워진) 단어장 주소.
class MissingBookScreen extends StatelessWidget {
  const MissingBookScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const Center(child: Text('없는 단어장입니다')),
  );
}
