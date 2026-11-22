import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_settings.dart';
import '../../data/cell.dart';
import '../../data/speaker.dart';
import '../../data/study_records.dart';
import '../../data/word.dart';
import '../../data/word_repository.dart';
import '../common/leave_guard.dart';
import '../quiz/quiz.dart' show quizRandomProvider;

/// 카드 학습: 칸·단어장의 단어를 한 장씩 넘겨 본다.
/// 앞면 영단어 + 발음, 누르면 뒷면 뜻·예문·해석. 이전/다음으로 오가며 스스로 채점하지 않는다
/// (2026-11-22 사용자 결정 — 안다/모른다를 없앴다. 오답 노트는 시험에서 틀린 단어만 담는다).
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.deck});

  final Deck deck;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int _index = 0;
  bool _flipped = false;

  /// 마지막으로 자동 발음한 카드 번호. 같은 카드를 다시 그릴 때 또 읽지 않게 한다.
  int? _spokenIndex;

  /// 기록을 저장하는 중. 이때는 버튼을 막아 연타로 두 번 기록되지 않게 한다.
  bool _saving = false;

  /// 이번 회차에 저장하지 못한 기록이 있었나.
  bool _saveFailed = false;

  void _speak(Word word) => ref.read(speakerProvider).speak(word.word);

  /// 이번 회차에 이미 기록한 단어 id. 이전으로 돌아갔다가 다시 넘겨도 또 기록하지 않는다.
  final Set<String> _recorded = {};

  /// 다음: 지나는 카드를 본 것으로 기록한다(공부 수 = 넘겨 본 카드 수, 한 회차에 카드당 한 번).
  Future<void> _next(Word word) async {
    if (_saving) return;
    setState(() => _saving = true);
    if (!_recorded.contains(word.id)) {
      try {
        await ref
            .read(studyRecordsProvider)
            .recordCardViewed(deck: widget.deck, word: word);
        _recorded.add(word.id); // 저장에 실패한 카드는 다시 지날 때 한 번 더 해 본다
      } catch (_) {
        // 스낵바는 아래 버튼을 덮으므로 쓰지 않고, 진행 표시 아래에 문구로 알린다
        _saveFailed = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _index++;
      _flipped = false;
      _saving = false;
    });
  }

  /// 이전: 기록하지 않고 앞 카드의 앞면으로.
  void _previous() => setState(() {
    _index--;
    _flipped = false;
  });

  /// 이번 회차의 카드 순서. 처음 단어를 읽을 때 섞고, 다시 하기 때 새로 섞는다.
  List<Word>? _order;

  void _restart() => setState(() {
    _order = null; // 다음 build에서 새로 섞는다
    _recorded.clear(); // 새 회차는 새로 센다
    _index = 0;
    _flipped = false;
    _spokenIndex = null;
    _saveFailed = false;
  });

  /// 읽어 둔 단어 수. 도중인지(끝 화면이 아닌지) 가릴 때 쓴다.
  int _total = 0;

  /// 도중: 첫 카드에서 아직 아무것도 안 했거나 끝 화면이면 아니다.
  bool get _inProgress => _index < _total && (_index > 0 || _flipped);

  @override
  Widget build(BuildContext context) {
    // 설정을 읽은 뒤에야 카드를 만든다(읽는 동안 엉뚱한 개수가 보이지 않게)
    final words = ref.watch(deckWordsProvider(widget.deck));
    final settings = ref.watch(appSettingsProvider);
    return LeaveGuard(
      // 도중에 ← 뒤로(앱바·시스템)를 누르면 먼저 묻는다(2026-11-22 사용자 결정(UX 점검))
      inProgress: _inProgress,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.deck.label} - 카드 학습',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: switch ((words, settings)) {
            (AsyncError(), _) => const Center(child: Text('단어를 읽지 못했습니다')),
            (AsyncData(value: final loaded), AsyncData(value: final s)) =>
              _content(loaded, s.cardCount),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }

  Widget _content(List<Word> loaded, int cardCount) {
    // 카드는 회차마다 무작위 순서로 나온다(2026-11-22 사용자 결정 — 전에는 저장된 순서).
    // 한 회차 동안은 순서를 붙잡아 이전/다음이 같은 카드로 오간다.
    // 설정한 수(없으면 있는 만큼)만 앞에서 잘라 쓴다 — 회차를 시작할 때 정해지고 도중에 바뀌지 않는다
    final list = _order ??= ([
      ...loaded,
    ]..shuffle(ref.read(quizRandomProvider))).take(cardCount).toList();
    _total = list.length;
    if (list.isEmpty) {
      // 화면에는 "칸"이라는 말을 쓰지 않는다(2026-11-20 사용자 결정)
      return const Center(child: Text('아직 단어가 없습니다'));
    }
    if (_index >= list.length) return _summary(list.length);
    return _card(list[_index], list.length);
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('study-previous'),
                  onPressed: _index == 0 || _saving ? null : _previous,
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('study-next'),
                  onPressed: _saving ? null : () => _next(word),
                  child: const Text('다음'),
                ),
              ),
            ],
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
        // 내 단어장 단어는 예문·해석이 없을 수 있다(선택) — 빈 줄은 그리지 않는다
        if (word.example.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            word.example,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        if (word.exampleMeaning.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            word.exampleMeaning,
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
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
          if (_saveFailed) ...[
            const SizedBox(height: 8),
            Text(
              '일부 기록을 저장하지 못했습니다',
              key: const ValueKey('study-save-failed'),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          // 돌아가기는 위쪽 ← 뒤로
          FilledButton(onPressed: _restart, child: const Text('다시 하기')),
        ],
      ),
    );
  }
}
