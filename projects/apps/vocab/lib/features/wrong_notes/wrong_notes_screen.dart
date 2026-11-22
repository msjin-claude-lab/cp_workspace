import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_records.dart';
import '../../data/word_repository.dart';
import '../quiz/quiz.dart';
import 'review_words.dart';

/// 오답 노트(칸 홈·단어장 화면 → 오답 노트): 그 칸·단어장의 오답을 최근에 틀린 것부터 보여 준다.
/// 오답 시험을 하고, 단어를 직접 지울 수 있다(카드로 다시 보기는 2026-11-22 사용자 결정으로 뺐다).
/// 오답 시험에서 맞힌 단어는 노트에서 빠진다(2026-11-20 사용자 결정).
class WrongNotesScreen extends ConsumerWidget {
  const WrongNotesScreen({super.key, required this.deck});

  final Deck deck;

  /// 오답 시험에서 돌아오면 노트를 다시 읽는다(맞혀서 빠진 단어 반영).
  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    if (ModalRoute.of(context)?.isCurrent != true) return; // 빠른 두 번 누름
    await context.push(path);
    if (context.mounted) ref.invalidate(deckWrongNotesProvider(deck));
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    WrongEntry e,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final records = ref.read(studyRecordsProvider);
    // 되돌리기는 화면을 나간 뒤에도 눌릴 수 있어 ref 대신 컨테이너로 다시 읽게 한다
    final container = ProviderScope.containerOf(context);
    try {
      await records.removeWrongNote(e.note.deck, e.note.wordId);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          // 떠 있는 스낵바가 목록 마지막 줄을 덮지 않게 한다(목록 아래 여백도 둔다)
          behavior: SnackBarBehavior.floating,
          content: Text('${e.word.word} — 오답 노트에서 지웠습니다'),
          action: SnackBarAction(
            key: const ValueKey('wrong-undo'),
            label: '되돌리기', // 2026-11-22 사용자 결정(UX 점검) — 틀린 횟수·시각 그대로 되살린다
            onPressed: () async {
              try {
                await records.restoreWrongNote(e.note);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('되돌리지 못했습니다')),
                );
              }
              container.invalidate(deckWrongNotesProvider(deck));
            },
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('지우지 못했습니다')));
    }
    if (context.mounted) ref.invalidate(deckWrongNotesProvider(deck));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(wrongEntriesProvider(deck));
    final text = Theme.of(context).textTheme;
    // 오답 시험의 보기는 묶음 전체에서 고른다 — 묶음으로 시험을 낼 수 없으면(단어가 4개 미만 등)
    // 버튼을 막고 까닭을 보여 준다. 그때는 직접 지우기로만 노트에서 뺄 수 있다
    final pool = ref.watch(deckWordsProvider(deck)).value;
    final quizBlocked = pool == null ? null : quizBlockReason(pool);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${deck.label} - 오답 노트',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('오답 노트를 읽지 못했습니다')),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                key: ValueKey('wrong-empty'),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '오답 노트가 비어 있습니다.\n시험에서 틀린 단어가 여기에 모입니다',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView(
              // 아래 여백: 스낵바가 떠 있어도 마지막 줄을 끝까지 올려 볼 수 있게
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${list.length}단어',
                    key: const ValueKey('wrong-count'),
                    style: text.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    key: const ValueKey('wrong-quiz'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('오답 시험'),
                    onPressed: quizBlocked != null
                        ? null
                        : () => _open(context, ref, '/review/quiz/${deck.id}'),
                  ),
                ),
                if (quizBlocked != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      quizBlocked,
                      key: const ValueKey('wrong-quiz-locked'),
                      style: text.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                for (final e in list)
                  ListTile(
                    key: ValueKey('wrong-${e.note.wordId}'),
                    title: Text(e.word.word),
                    subtitle: Text(e.word.meaning),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('틀림 ${e.note.missCount}', style: text.bodySmall),
                        IconButton(
                          key: ValueKey('wrong-delete-${e.note.wordId}'),
                          tooltip: '오답 노트에서 지우기',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(context, ref, e),
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
