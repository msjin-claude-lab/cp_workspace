import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/speaker.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';
import '../wrong_notes/review_words.dart';

/// 카드 학습: 칸의 단어를 한 장씩 본다.
/// 앞면 영단어 + 발음, 누르면 뒷면 뜻·예문·해석 → 안다/모른다 → 다음 카드.
/// `review`면 그 칸의 오답 노트 단어만 본다(오답 노트 → 카드로 다시 보기).
/// '안다'로 답해도 오답 노트에서 빼지 않는다(사용자 결정 — 빠지는 것은 오답 시험에서 맞혔을 때).
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.cell, this.review = false});

  final Cell cell;
  final bool review;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int _index = 0;
  bool _flipped = false;
  int _known = 0;
  int _unknown = 0;

  /// 마지막으로 자동 발음한 카드 번호. 같은 카드를 다시 그릴 때 또 읽지 않게 한다.
  int? _spokenIndex;

  /// 답을 저장하는 중. 이때는 버튼을 막아 연타로 두 번 기록되지 않게 한다.
  bool _answering = false;

  /// 이번 회차에 저장하지 못한 답이 있었나.
  bool _saveFailed = false;

  /// 다시 보기(review)에서 처음 받은 오답 단어 목록.
  List<Word>? _reviewWords;

  void _speak(Word word) => ref.read(speakerProvider).speak(word.word);

  Future<void> _answer(Word word, {required bool known}) async {
    if (_answering) return;
    setState(() => _answering = true);
    try {
      await ref
          .read(studyRecordsProvider)
          .recordAnswer(cell: widget.cell, word: word, known: known);
    } catch (_) {
      // 스낵바는 아래 버튼을 덮으므로 쓰지 않고, 진행 표시 아래에 문구로 알린다
      _saveFailed = true;
    }
    if (!mounted) return;
    setState(() {
      known ? _known++ : _unknown++;
      _index++;
      _flipped = false;
      _answering = false;
    });
  }

  void _restart() => setState(() {
    _index = 0;
    _flipped = false;
    _known = 0;
    _unknown = 0;
    _spokenIndex = null;
    _saveFailed = false;
  });

  /// 결과 화면의 돌아가기: 연 화면(칸 홈·오답 노트)으로. 주소로 바로 열었으면 칸 홈으로.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.review
        ? ref.watch(reviewWordsProvider(widget.cell))
        : ref.watch(cellWordsProvider(widget.cell));
    // 다시 보기는 처음 받은 오답 목록을 회차 동안 붙잡는다 — 노트가 다시 읽혀도 카드가 건너뛰지 않게
    final words = switch (source) {
      AsyncData(:final value) when widget.review => AsyncData(
        _reviewWords ??= value,
      ),
      _ when _reviewWords != null => AsyncData(_reviewWords!),
      _ => source,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.review
              ? '${widget.cell.label} - 오답 다시 보기'
              : '${widget.cell.label} - 카드 학습',
        ),
      ),
      body: SafeArea(
        child: words.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('단어를 읽지 못했습니다')),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Text(
                  widget.review ? '오답 노트에 단어가 없습니다' : '이 칸에는 아직 단어가 없습니다',
                ),
              );
            }
            if (_index >= list.length) return _summary(list.length);
            return _card(list[_index], list.length);
          },
        ),
      ),
    );
  }

  Widget _card(Word word, int total) {
    if (_spokenIndex != _index) {
      _spokenIndex = _index;
      // 새 카드가 처음 그려진 뒤 한 번만 읽는다(뒤집거나 다시 그릴 때는 읽지 않음)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak(word);
      });
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: _index / total),
          const SizedBox(height: 8),
          Text(
            '${_index + 1} / $total',
            key: const ValueKey('study-progress'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (_saveFailed)
            Text(
              '기록을 저장하지 못했습니다',
              key: const ValueKey('study-save-error'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              key: const ValueKey('study-card'),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _flipped = !_flipped),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _flipped ? _back(word) : _front(word),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_flipped)
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    key: const ValueKey('study-unknown'),
                    onPressed: _answering
                        ? null
                        : () => _answer(word, known: false),
                    child: const Text('모른다'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('study-known'),
                    onPressed: _answering
                        ? null
                        : () => _answer(word, known: true),
                    child: const Text('안다'),
                  ),
                ),
              ],
            )
          else
            Text(
              '카드를 누르면 뜻이 보입니다',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _front(Word word) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word.word, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        IconButton(
          key: const ValueKey('study-speak'),
          iconSize: 36,
          tooltip: '발음 듣기',
          icon: const Icon(Icons.volume_up),
          onPressed: () => _speak(word),
        ),
      ],
    );
  }

  Widget _back(Word word) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(word.word, style: text.titleMedium),
        const SizedBox(height: 8),
        Text(
          word.meaning,
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 24),
        Text(
          word.example,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 4),
        Text(
          word.exampleMeaning,
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
      ],
    );
  }

  Widget _summary(int total) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$total단어를 모두 봤습니다',
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '안다 $_known · 모른다 $_unknown',
            key: const ValueKey('study-summary'),
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          if (_saveFailed) ...[
            const SizedBox(height: 4),
            Text(
              '일부 기록을 저장하지 못했습니다',
              key: const ValueKey('study-save-failed'),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ] else if (_unknown > 0 && !widget.review) ...[
            const SizedBox(height: 4),
            Text(
              "'모른다' 단어는 오답 노트에 담았습니다",
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ] else if (widget.review) ...[
            const SizedBox(height: 4),
            Text(
              '오답 노트에서 빼려면 오답 시험에서 맞히세요',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _restart, child: const Text('다시 하기')),
          // 돌아가기는 위쪽 ← 뒤로. 오답 노트에서 열었으면 노트로 돌아가는 버튼을 하나 더 둔다
          if (widget.review) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _leave, child: const Text('오답 노트로')),
          ],
        ],
      ),
    );
  }
}
