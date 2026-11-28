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
import '../reminder/reminder_controller.dart';
import '../../data/study_decks.dart';
import '../today/today_words.dart';
import 'card_pick.dart';

/// 카드 학습: 칸·단어장의 단어를 한 장씩 넘겨 본다.
/// 앞면 영단어 + 발음, 누르면 뒷면 뜻·예문·해석. 이전/다음으로 오가며 스스로 채점하지 않는다
/// (2026-11-22 사용자 결정 — 안다/모른다를 없앴다. 오답 노트는 시험에서 틀린 단어만 담는다).
///
/// `today`면 오늘의 단어(2026-11-28 사용자 결정): 그날 고른 단어(`todayWordsProvider`)를 고른 순서대로
/// 같은 카드로 보고, 넘긴 카드는 카드 학습과 똑같이 기록하며 그날 묶음에 본 것으로도 남긴다.
/// 고른 단어를 모두 넘기면 그날 완료 — 매일 알림을 다시 예약해 오늘 것을 뺀다. 이름 있는 단어장만.
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.deck, this.today = false})
    : assert(!today || deck is StudyDeck);

  final Deck deck;
  final bool today;

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

  /// 이 화면을 연 뒤 넘겨 본 단어 id(회차를 넘어 쌓인다). 다시 하기 때 DB를 다시 읽지 않고
  /// 이것을 더해 "안 본 단어"를 가린다.
  final Set<String> _viewedHere = {};

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
        _viewedHere.add(word.id);
      } catch (_) {
        // 스낵바는 아래 버튼을 덮으므로 쓰지 않고, 진행 표시 아래에 문구로 알린다
        _saveFailed = true;
      }
    }
    if (widget.today) await _markTodaySeen(word);
    if (!mounted) return;
    setState(() {
      _index++;
      _flipped = false;
      _saving = false;
      _advanced = true;
    });
  }

  /// 오늘의 단어를 고른 날. 화면을 연 채 자정을 넘겨도 본 것은 이 날의 묶음에 남긴다.
  String? _todayDay;

  /// 오늘의 단어를 이미 끝냈나(이 화면에서 끝낸 순간 한 번만 알림을 다시 예약한다).
  bool _todayDone = false;

  /// 오늘의 단어 묶음에 본 것으로 남긴다. 이번에 모두 보게 되면 알림을 다시 예약한다(오늘 알림을 뺀다).
  Future<void> _markTodaySeen(Word word) async {
    final deck = widget.deck as StudyDeck;
    final day = _todayDay;
    if (day == null || !mounted) return;
    try {
      final set = await ref
          .read(studyDecksProvider)
          .markDailySeen(deck.deckId, day, word.id);
      if (set != null && set.completed && !_todayDone) {
        _todayDone = true;
        await ref.read(reminderControllerProvider.notifier).reschedule();
      }
    } catch (_) {
      _saveFailed = true;
    }
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
    _advanced = false;
    _spokenIndex = null;
    _saveFailed = false;
  });

  /// 이번 회차에 카드를 한 번이라도 넘겼나. 이전으로 첫 카드에 돌아와도 도중으로 본다.
  bool _advanced = false;

  /// 도중: 첫 카드에서 아직 아무것도 안 했거나 끝 화면이면 아니다.
  /// 붙잡아 둔 카드 목록(`_order`)의 길이로 끝 화면인지 가린다.
  bool get _inProgress =>
      _index < (_order?.length ?? 0) && (_advanced || _index > 0 || _flipped);

  @override
  Widget build(BuildContext context) {
    final (list, failed) = widget.today ? _todayList() : _studyList();
    return LeaveGuard(
      // 도중에 ← 뒤로(앱바·시스템)를 누르면 먼저 묻는다(2026-11-22 사용자 결정(UX 점검))
      inProgress: _inProgress,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.deck.label} - ${widget.today ? '오늘의 단어' : '카드 학습'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: failed
              ? const Center(child: Text('단어를 읽지 못했습니다'))
              : list == null
              ? const Center(child: CircularProgressIndicator())
              : _content(list),
        ),
      ),
    );
  }

  /// 카드 학습의 이번 회차 카드. 아직 읽는 중이면 null, 단어를 읽지 못했으면 failed.
  (List<Word>?, bool) _studyList() {
    // 설정을 읽은 뒤에야 카드를 만든다(읽는 동안 엉뚱한 개수가 보이지 않게)
    final words = ref.watch(deckWordsProvider(widget.deck));
    final settings = ref.watch(deckSettingsProvider(widget.deck));
    // 넘겨 본 기록을 못 읽어도 학습은 막지 않는다 — 안 본 단어 구분 없이 뽑는다.
    // Riverpod이 실패한 읽기를 다시 시도하는 동안은 AsyncError가 아니라 오류를 든 로딩이라
    // hasError로 본다(AsyncError만 보면 다시 시도가 끝날 때까지 수십 초 로딩만 보인다)
    final viewedAsync = ref.watch(viewedWordIdsProvider(widget.deck));
    final viewed =
        viewedAsync.value ?? (viewedAsync.hasError ? const <String>{} : null);
    switch ((words, settings)) {
      case (AsyncError(), _):
        return (null, true);
      case (AsyncData(value: final loaded), AsyncData(value: final s))
          when viewed != null:
        // 카드는 회차마다 무작위로 나온다(2026-11-22 사용자 결정 — 전에는 저장된 순서).
        // 20%는 전체에서, 80%는 안 본 단어 먼저(2026-11-23 사용자 결정 — pickCards).
        // 한 회차 동안은 순서를 붙잡아 이전/다음이 같은 카드로 오간다.
        // 설정한 수(없으면 있는 만큼)만 낸다 — 회차를 시작할 때 정해지고 도중에 바뀌지 않는다
        return (
          _order ??= pickCards(
            loaded,
            {...viewed, ..._viewedHere},
            s.cardCount,
            ref.read(quizRandomProvider),
          ),
          false,
        );
      default:
        return (null, false);
    }
  }

  /// 오늘의 단어: 그날 고른 단어를 고른 순서대로(다시 하기도 같은 순서).
  (List<Word>?, bool) _todayList() {
    final today = ref.watch(todayWordsProvider(widget.deck as StudyDeck));
    if (today.value case final t?) {
      if (_todayDay == null) {
        _todayDay = t.day;
        _todayDone = t.completed;
      }
      return (_order ??= t.words, false);
    }
    return (null, today.hasError);
  }

  Widget _content(List<Word> list) {
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
          // 막대는 아래 숫자(지금 카드 / 전체)와 같이 간다 — 첫 카드에서도 비어 보이지 않는다
          LinearProgressIndicator(value: (_index + 1) / total),
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
                  // 가로 화면·큰 글꼴에서 뒷면이 카드보다 길면 넘치지 않고 스크롤된다
                  child: SingleChildScrollView(
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
        // 뒷면에서도 다시 들을 수 있게 한다(버튼을 눌러도 카드는 뒤집히지 않는다)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(word.word, style: text.titleMedium)),
            IconButton(
              key: const ValueKey('study-speak-back'),
              tooltip: '발음 듣기',
              icon: const Icon(Icons.volume_up),
              onPressed: () => _speak(word),
            ),
          ],
        ),
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
            widget.today ? '오늘의 단어 $total개를 모두 봤습니다' : '$total단어를 모두 봤습니다',
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
