import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/speaker.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';
import '../common/leave_guard.dart';
import '../wrong_notes/review_words.dart';
import 'quiz.dart';

/// 4지선다 시험: 칸·단어장의 단어 20개를 섞어 영→뜻·뜻→영으로 묻는다.
/// 보기를 누르면 맞았는지와 정답·예문·해석을 보여 주고, 틀리면 오답 노트에 넣는다.
/// `review`면 오답 시험: 그 칸·단어장의 오답 노트 단어만 묻고(보기는 그 묶음 전체에서), 맞힌 단어는
/// 노트에서 뺀다(2026-11-20 사용자 결정).
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.deck, this.review = false});

  final Deck deck;
  final bool review;

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

  /// 오답 시험에서 맞혀 노트에서 뺀 단어 id. 다시 하기 때 이 단어는 묻지 않는다.
  final Set<String> _removed = {};

  /// 이번 회차에 틀린 단어(결과 화면에 보인다).
  final List<Word> _wrongWords = [];

  /// 답한 뒤 보이는 풀이의 자리(답하면 여기까지 스크롤한다).
  final GlobalKey _explanationKey = GlobalKey();

  /// 도중: 첫 문제에서 아직 답하지 않았거나 결과 화면이면 아니다.
  /// 붙잡아 둔 문제 목록(`_questions`)의 길이로 결과 화면인지 가린다.
  bool get _inProgress =>
      _index < (_questions?.length ?? 0) && (_index > 0 || _chosen != null);

  void _speak(Word word) => ref.read(speakerProvider).speak(word.word);

  Future<void> _choose(QuizQuestion q, int option) async {
    if (_chosen != null) return; // 한 문제에 한 번만 답한다
    final correct = option == q.answerIndex;
    final remove = widget.review && correct;
    setState(() {
      _chosen = option;
      if (correct) {
        _correct++;
      } else {
        _wrongWords.add(q.word);
      }
      // 저장이 끝나기 전에 다시 하기를 눌러도 맞힌 단어가 다시 나오지 않게 먼저 표시한다
      if (remove) _removed.add(q.word.id);
    });
    // "다음 문제" 버튼이 늘 보이므로, 풀이가 화면 아래에 숨은 채 넘어가지 않게 풀이까지 내려 준다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shown = _explanationKey.currentContext;
      if (shown == null) return;
      Scrollable.ensureVisible(
        shown,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
    final records = ref.read(studyRecordsProvider);
    try {
      await records.recordQuizAnswer(
        deck: widget.deck,
        word: q.word,
        correct: correct,
      );
      // 기록 저장이 실패하면 노트에서도 빼지 않는다(기록 없이 노트만 빠지지 않게)
      if (remove) await records.removeWrongNote(widget.deck, q.word.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveFailed = true;
          _removed.remove(q.word.id); // 노트에 남았으니 다시 하기에서 다시 묻는다
        });
      }
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
    _wrongWords.clear();
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
    final all = ref.watch(deckWordsProvider(widget.deck));
    // 오답 시험은 노트 단어만 묻는다. 일반 시험은 칸·단어장 전체
    final asked = widget.review
        ? ref.watch(reviewWordsProvider(widget.deck))
        : all;
    return LeaveGuard(
      // 도중에 ← 뒤로(앱바·시스템)를 누르면 먼저 묻는다(2026-11-22 사용자 결정(UX 점검))
      inProgress: _inProgress,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.review
                ? '${widget.deck.label} - 오답 시험'
                : '${widget.deck.label} - 시험',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          // 설정을 읽은 뒤에야 문제를 만든다(읽는 동안 엉뚱한 문항 수가 보이지 않게)
          child: switch ((
            asked,
            all,
            ref.watch(deckSettingsProvider(widget.deck)),
          )) {
            (
              AsyncData(value: final words),
              AsyncData(value: final pool),
              AsyncData(value: final s),
            ) =>
              _body(words, pool, s.quizCount),
            (AsyncError(), _, _) ||
            (_, AsyncError(), _) => const Center(child: Text('단어를 읽지 못했습니다')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }

  Widget _body(List<Word> words, List<Word> pool, int length) {
    final questions = _questions ??= buildQuiz(
      [
        for (final w in words)
          if (!_removed.contains(w.id)) w,
      ],
      ref.read(quizRandomProvider),
      length: length,
      pool: pool,
    );
    if (questions.isEmpty) {
      // 시험을 낼 수 없는 까닭이 있으면 그것을, 아니면(오답 시험에서 다 맞힘) 남은 단어가 없다고 알린다
      final reason = quizBlockReason(pool);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            reason ?? '오답 노트에 남은 단어가 없습니다',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_index >= questions.length) return _summary(questions.length);
    return _question(questions[_index], questions.length);
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
    // 문제·보기·풀이는 스크롤되고, "다음 문제" 버튼은 화면 맨 아래 같은 자리에 둔다
    // (풀이 길이에 따라 버튼이 오르내리지 않게 — UX 점검)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _questionScroll(q, total, toMeaning, answered, theme)),
        if (answered)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              key: const ValueKey('quiz-next'),
              onPressed: _next,
              child: Text(_index + 1 < total ? '다음 문제' : '결과 보기'),
            ),
          ),
      ],
    );
  }

  Widget _questionScroll(
    QuizQuestion q,
    int total,
    bool toMeaning,
    bool answered,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      // 문제마다 새 스크롤 — 앞 문제에서 풀이까지 내린 위치가 다음 문제에 남지 않는다
      key: ValueKey('quiz-scroll-$_index'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 막대는 아래 숫자(지금 문제 / 전체)와 같이 간다 — 첫 문제에서도 비어 보이지 않는다
          LinearProgressIndicator(value: (_index + 1) / total),
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
            KeyedSubtree(key: _explanationKey, child: _explanation(q)),
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

  /// 오답 노트 보기: 시험 화면을 노트로 바꿔 열어 ← 뒤로가 홈으로 가게 한다
  /// (시험 화면을 남겨 두면 뒤로가 끝난 시험으로 돌아온다).
  void _openWrongNotes() {
    if (ModalRoute.of(context)?.isCurrent != true) return; // 빠른 두 번 누름
    _refreshWrongNotes();
    context.pushReplacement('/wrong-notes/${widget.deck.id}');
  }

  void _goHome() {
    _refreshWrongNotes();
    context.go('/');
  }

  /// 결과 화면의 버튼은 ← 뒤로가 아니라서 홈의 "돌아오면 노트를 다시 읽기"가 돌지 않는다
  /// (pushReplacement·go는 홈이 기다리는 push를 끝내지 않는다). 떠나기 전에 직접 다시 읽게 한다.
  void _refreshWrongNotes() =>
      ref.invalidate(deckWrongNotesProvider(widget.deck));

  Widget _summary(int total) {
    final text = Theme.of(context).textTheme;
    final wrong = total - _correct;
    final percent = total == 0 ? 0 : (_correct * 100 / total).round();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$total문제 중 $_correct문제 맞혔습니다',
              key: const ValueKey('quiz-summary'),
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              key: const ValueKey('quiz-percent'),
              textAlign: TextAlign.center,
              style: text.headlineMedium,
            ),
            ..._summaryBody(text, wrong),
          ],
        ),
      ),
    );
  }

  /// 결과의 나머지: 저장 실패·오답 노트 안내·이번에 틀린 단어·버튼.
  List<Widget> _summaryBody(TextTheme text, int wrong) {
    return [
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
      ] else if (widget.review) ...[
        if (_correct > 0) ...[
          const SizedBox(height: 4),
          Text(
            '맞힌 $_correct단어는 오답 노트에서 뺐습니다',
            key: const ValueKey('quiz-review-removed'),
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
        if (wrong > 0) ...[
          const SizedBox(height: 4),
          Text(
            '틀린 $wrong단어는 오답 노트에 남았습니다',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
      ] else if (wrong > 0) ...[
        const SizedBox(height: 4),
        // 새로 담긴 개수는 말하지 않는다 — 이미 노트에 있던 단어도 있어 개수가 맞지 않는다
        Text(
          '틀린 단어는 오답 노트에 있습니다',
          key: const ValueKey('quiz-wrong-in-notes'),
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
      ],
      if (_wrongWords.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('이번에 틀린 단어', style: text.titleMedium),
        const SizedBox(height: 4),
        for (final w in _wrongWords)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${w.word} — ${w.meaning}',
              key: ValueKey('quiz-wrong-${w.id}'),
              style: text.bodyLarge,
            ),
          ),
      ],
      const SizedBox(height: 24),
      FilledButton(
        key: const ValueKey('quiz-again'),
        onPressed: _restart,
        child: Text(widget.review ? '남은 오답 다시 하기' : '다시 하기'),
      ),
      if (widget.review) ...[
        // 오답 노트에서 열었으면 노트로 돌아가는 버튼을 하나 더 둔다
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _backToCells, child: const Text('오답 노트로')),
      ] else ...[
        if (wrong > 0) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('quiz-to-notes'),
            onPressed: _openWrongNotes,
            child: const Text('오답 노트 보기'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('quiz-home'),
          onPressed: _goHome,
          child: const Text('홈으로'),
        ),
      ],
    ];
  }
}
