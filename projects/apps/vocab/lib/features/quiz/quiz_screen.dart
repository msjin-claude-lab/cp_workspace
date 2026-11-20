import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/speaker.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';
import 'quiz.dart';

/// 4지선다 시험: 칸의 단어 10개를 섞어 영→뜻·뜻→영으로 묻는다.
/// 보기를 누르면 맞았는지와 정답·예문·해석을 보여 주고, 틀리면 오답 노트에 넣는다.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.cell});

  final Cell cell;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  /// 이번 회차 문제. 단어를 읽은 뒤 한 번 만들고, 다시 하기 때 새로 섞는다.
  List<QuizQuestion>? _questions;
  int _index = 0;

  /// 지금 문제에서 고른 보기 번호. null이면 아직 고르지 않았다.
  int? _chosen;
  int _correct = 0;

  /// 마지막으로 자동 발음한 문제 번호.
  int? _spokenIndex;

  /// 이번 회차에 저장하지 못한 답이 있었나.
  bool _saveFailed = false;

  void _speak(Word word) => ref.read(speakerProvider).speak(word.word);

  Future<void> _choose(QuizQuestion q, int option) async {
    if (_chosen != null) return; // 한 문제에 한 번만 답한다
    final correct = option == q.answerIndex;
    setState(() {
      _chosen = option;
      if (correct) _correct++;
    });
    try {
      await ref
          .read(studyRecordsProvider)
          .recordQuizAnswer(cell: widget.cell, word: q.word, correct: correct);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  void _next() => setState(() {
    _index++;
    _chosen = null;
  });

  void _restart() => setState(() {
    _questions = null; // 다음 build에서 새로 섞는다
    _index = 0;
    _chosen = null;
    _correct = 0;
    _spokenIndex = null;
    _saveFailed = false;
  });

  void _backToCells() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(cellWordsProvider(widget.cell));
    return Scaffold(
      appBar: AppBar(title: Text('${widget.cell.label} 시험')),
      body: SafeArea(
        child: words.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('단어를 읽지 못했습니다')),
          data: (list) {
            final questions = _questions ??= buildQuiz(
              list,
              ref.read(quizRandomProvider),
            );
            if (questions.isEmpty) {
              return const Center(
                child: Text('단어가 $quizOptionCount개 이상 있어야 시험을 볼 수 있습니다'),
              );
            }
            if (_index >= questions.length) return _summary(questions.length);
            return _question(questions[_index], questions.length);
          },
        ),
      ),
    );
  }

  Widget _question(QuizQuestion q, int total) {
    final toMeaning = q.direction == QuizDirection.wordToMeaning;
    if (toMeaning && _spokenIndex != _index) {
      _spokenIndex = _index;
      // 영→뜻 문제는 처음 그려질 때 한 번 읽는다. 뜻→영은 답을 알려 주게 되므로 읽지 않는다
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak(q.word);
      });
    }
    final theme = Theme.of(context);
    final answered = _chosen != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: _index / total),
          const SizedBox(height: 8),
          Text(
            '${_index + 1} / $total',
            key: const ValueKey('quiz-progress'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (_saveFailed)
            Text(
              '기록을 저장하지 못했습니다',
              key: const ValueKey('quiz-save-error'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            toMeaning ? '뜻을 고르세요' : '영단어를 고르세요',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            q.prompt,
            key: const ValueKey('quiz-prompt'),
            textAlign: TextAlign.center,
            style: toMeaning
                ? theme.textTheme.displaySmall
                : theme.textTheme.headlineMedium,
          ),
          if (toMeaning)
            Center(
              child: IconButton(
                key: const ValueKey('quiz-speak'),
                iconSize: 32,
                tooltip: '발음 듣기',
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speak(q.word),
              ),
            ),
          const SizedBox(height: 24),
          for (var i = 0; i < q.options.length; i++) ...[
            _option(q, i),
            const SizedBox(height: 8),
          ],
          if (answered) ...[
            const SizedBox(height: 8),
            _explanation(q),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('quiz-next'),
              onPressed: _next,
              child: Text(_index + 1 < total ? '다음 문제' : '결과 보기'),
            ),
          ],
        ],
      ),
    );
  }

  /// 보기 버튼. 답한 뒤에는 정답을 초록, 고른 오답을 빨강으로 칠하고 더 누를 수 없다.
  Widget _option(QuizQuestion q, int i) {
    final scheme = Theme.of(context).colorScheme;
    final answered = _chosen != null;
    final isAnswer = i == q.answerIndex;
    final isWrongChoice = answered && i == _chosen && !isAnswer;
    Color? background;
    if (answered && isAnswer) background = Colors.green.shade100;
    if (isWrongChoice) background = scheme.errorContainer;
    return OutlinedButton(
      key: ValueKey('quiz-option-$i'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        backgroundColor: background,
        disabledBackgroundColor: background,
        disabledForegroundColor: scheme.onSurface,
      ),
      onPressed: answered ? null : () => _choose(q, i),
      child: Text(
        q.optionText(q.options[i]),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _explanation(QuizQuestion q) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final correct = _chosen == q.answerIndex;
    return Card(
      key: const ValueKey('quiz-explanation'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              correct ? '정답입니다' : '틀렸습니다',
              key: const ValueKey('quiz-result'),
              style: text.titleMedium?.copyWith(
                color: correct ? Colors.green.shade800 : scheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${q.word.word} — ${q.word.meaning}',
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '발음 듣기',
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _speak(q.word),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.word.example,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              q.word.exampleMeaning,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(int total) {
    final text = Theme.of(context).textTheme;
    final wrong = total - _correct;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$total문제 중 $_correct문제 맞혔습니다',
            key: const ValueKey('quiz-summary'),
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          if (_saveFailed) ...[
            const SizedBox(height: 4),
            Text(
              '일부 기록을 저장하지 못했습니다',
              key: const ValueKey('quiz-save-failed'),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ] else if (wrong > 0) ...[
            const SizedBox(height: 4),
            Text(
              '틀린 단어 $wrong개는 오답 노트에 담았습니다',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _restart, child: const Text('다시 하기 (새로 섞기)')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _backToCells, child: const Text('칸 선택으로')),
        ],
      ),
    );
  }
}
