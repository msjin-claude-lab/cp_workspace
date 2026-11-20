import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/word_books.dart';
import 'dialogs.dart';

/// 내 단어장 목록(☰ 메뉴 → 내 단어장): 단어장을 여러 개 만들고(명세), 이름을 바꾸거나 지운다.
/// 단어장을 누르면 그 단어장 화면으로 간다.
class WordBooksScreen extends ConsumerStatefulWidget {
  const WordBooksScreen({super.key});

  @override
  ConsumerState<WordBooksScreen> createState() => _WordBooksScreenState();
}

class _WordBooksScreenState extends ConsumerState<WordBooksScreen> {
  /// 저장 중. 이때는 만들기·바꾸기·지우기를 다시 받지 않는다(두 번 저장 막기).
  bool _busy = false;

  /// 창을 띄워도 되나 — 이미 창이나 다른 화면이 위에 있으면(빠른 두 번 누름) 아무것도 하지 않는다.
  bool get _ready => !_busy && ModalRoute.of(context)?.isCurrent == true;

  /// DB 작업을 하고 목록을 다시 읽는다. 실패하면 알린다.
  Future<void> _run(Future<void> Function() work, String failMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await work();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failMessage)));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(wordBookListProvider);
  }

  Future<void> _create() async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final name = await showBookNameDialog(context, title: '단어장 만들기');
    if (name == null || !mounted) return;
    await _run(() => books.createBook(name), '단어장을 만들지 못했습니다');
  }

  Future<void> _rename(WordBook book) async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final name = await showBookNameDialog(
      context,
      title: '이름 바꾸기',
      initial: book.name,
    );
    if (name == null || name == book.name || !mounted) return;
    await _run(() => books.renameBook(book.id, name), '이름을 바꾸지 못했습니다');
  }

  Future<void> _delete(WordBook book) async {
    if (!_ready) return;
    final books = ref.read(wordBooksProvider);
    final ok = await confirmDelete(
      context,
      title: '${book.name} 단어장을 지울까요?',
      message: '단어 ${book.wordCount}개와 이 단어장의 오답 노트도 함께 지워집니다',
    );
    if (!ok || !mounted) return;
    await _run(() => books.deleteBook(book.id), '단어장을 지우지 못했습니다');
  }

  /// 단어장 화면에서 돌아오면 단어 수가 바뀌었을 수 있으니 다시 읽는다.
  Future<void> _open(WordBook book) async {
    if (!_ready) return;
    await context.push('/books/${book.id}');
    if (mounted) ref.invalidate(wordBookListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(wordBookListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 단어장')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('books-add'),
        icon: const Icon(Icons.add),
        label: const Text('단어장 만들기'),
        onPressed: _busy ? null : _create,
      ),
      body: SafeArea(
        child: books.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('단어장을 읽지 못했습니다')),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                key: ValueKey('books-empty'),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '아직 단어장이 없습니다.\n아래 "단어장 만들기"로 만들어 보세요',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView(
              // 아래 만들기 버튼이 마지막 줄을 가리지 않게 띄운다
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              children: [
                for (final book in list)
                  ListTile(
                    key: ValueKey('book-${book.id}'),
                    leading: const Icon(Icons.book_outlined),
                    title: Text(book.name),
                    subtitle: Text('${book.wordCount}단어'),
                    onTap: () => _open(book),
                    trailing: PopupMenuButton<String>(
                      key: ValueKey('book-menu-${book.id}'),
                      tooltip: '단어장 메뉴',
                      enabled: !_busy,
                      onSelected: (action) =>
                          action == 'rename' ? _rename(book) : _delete(book),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          key: ValueKey('book-rename'),
                          value: 'rename',
                          child: Text('이름 바꾸기'),
                        ),
                        PopupMenuItem(
                          key: ValueKey('book-delete'),
                          value: 'delete',
                          child: Text('지우기'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
