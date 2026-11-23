import 'dart:math';

import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/counts.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';

/// 시험(test)에서 함께 쓰는 가짜들. 모두 메모리에만 둔다.

/// 섞어도 순서가 바뀌지 않게 하는 난수(`List.shuffle`이 늘 제자리와 바꾸게 한다).
/// 카드 순서를 정해 두고 확인하는 시험에서 `quizRandomProvider`에 넣는다.
class NoShuffleRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Word fakeWord(String id, String word, String meaning) => Word(
  id: id,
  word: word,
  meaning: meaning,
  example: 'e $word',
  exampleMeaning: 'em $word',
);

/// 칸마다 정해 둔 단어를 돌려준다. 없는 칸은 빈 목록.
class FakeRepository implements WordRepository {
  FakeRepository(this.words);

  final Map<Cell, List<Word>> words;

  @override
  Future<List<Word>> wordsOf(Cell cell) async => words[cell] ?? const [];
}

/// 단어 읽기가 늘 실패한다(단어 파일을 읽지 못하는 경우).
class FailingRepository implements WordRepository {
  @override
  Future<List<Word>> wordsOf(Cell cell) async => throw StateError('asset');
}

/// `selectedDeck`이 기기에 저장된 고른 단어장 번호 역할. `legacyCell`·`legacyRegistered`는
/// 옛 버전이 남긴 고른 칸·등록 목록.
class FakeCellStore implements CellStore {
  FakeCellStore({this.selectedDeck, this.legacyCell});

  int? selectedDeck;
  Cell? legacyCell;
  List<Cell> legacyRegistered = [];
  bool fail = false;

  @override
  Future<int?> loadSelectedDeck() async => selectedDeck;

  @override
  Future<void> saveSelectedDeck(int deckId) async {
    if (fail) throw StateError('prefs');
    selectedDeck = deckId;
  }

  @override
  Future<Cell?> loadLegacyCell() async => legacyCell;

  @override
  Future<List<Cell>> loadLegacyRegistered() async => [...legacyRegistered];
}

/// 이름 있는 단어장을 메모리에 둔다. 지울 때 오답 노트·학습·시험 기록도 지우는 것을 흉내 내려면 `records`를 준다.
class FakeStudyDecks implements StudyDecks {
  FakeStudyDecks([this.records]);

  final FakeRecords? records;
  final List<StudyDeck> list = [];
  int _next = 1;
  bool migrated = false;

  /// 단어장 번호별 고유 설정(7판 `card_count`·`quiz_count`). 없으면 NULL — 7판 전에 있던 단어장.
  final Map<int, int> cardCounts = {};
  final Map<int, int> quizCounts = {};

  /// true면 설정 저장이 실패한다.
  bool failSave = false;

  /// true면 고유 설정 읽기가 실패한다.
  bool failLoad = false;

  /// 있으면 고유 설정 읽기가 이것이 끝날 때까지 걸린다(느린 DB 흉내).
  Future<void>? loadGate;

  /// 시험이 단어장을 미리 만들어 둘 때 쓴다. 설정을 주지 않으면 7판 전에 있던 단어장(열이 NULL).
  StudyDeck seed(String name, Cell base, {int? cardCount, int? quizCount}) {
    final deck = StudyDeck(deckId: _next++, name: name, base: base);
    list.add(deck);
    if (cardCount != null) cardCounts[deck.deckId] = cardCount;
    if (quizCount != null) quizCounts[deck.deckId] = quizCount;
    return deck;
  }

  @override
  Future<List<StudyDeck>> decks() async => [...list];

  /// 실제 구현처럼 새 단어장은 기본값을 명시적으로 저장한다.
  @override
  Future<StudyDeck> createDeck(String name, Cell base) async => seed(
    name,
    base,
    cardCount: defaultCardCount,
    quizCount: defaultQuizCount,
  );

  @override
  Future<DeckCounts> loadCounts(int deckId) async {
    if (loadGate case final gate?) await gate;
    if (failLoad) throw StateError('db');
    return (cardCount: cardCounts[deckId], quizCount: quizCounts[deckId]);
  }

  @override
  Future<void> saveCardCount(int deckId, int count) async {
    if (failSave) throw StateError('db');
    // 실제 구현(UPDATE)처럼 없는 단어장 번호면 아무것도 하지 않는다
    if (list.any((d) => d.deckId == deckId)) cardCounts[deckId] = count;
  }

  @override
  Future<void> saveQuizCount(int deckId, int count) async {
    if (failSave) throw StateError('db');
    if (list.any((d) => d.deckId == deckId)) quizCounts[deckId] = count;
  }

  @override
  Future<void> renameDeck(int deckId, String name) async {
    final i = list.indexWhere((d) => d.deckId == deckId);
    if (i >= 0) list[i] = list[i].renamed(name);
  }

  @override
  Future<void> deleteDeck(int deckId) async {
    final id = 'deck_$deckId';
    records?.removeDeckRecords(id);
    list.removeWhere((d) => d.deckId == deckId);
    cardCounts.remove(deckId);
    quizCounts.remove(deckId);
  }

  /// 실제 이행은 DB 시험(`study_decks_test.dart`)이 본다. 여기서는 한 번만 단어장을 만든다.
  @override
  Future<int?> migrateLegacy({
    required List<Cell> cells,
    Cell? selected,
  }) async {
    if (migrated) return null;
    migrated = true;
    int? selectedDeck;
    for (final cell in cells.toSet()) {
      final deck = seed(legacyDeckName(cell), cell);
      if (cell == selected) selectedDeck = deck.deckId;
    }
    return selectedDeck;
  }
}

class FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

/// 기록과 오답 노트를 메모리에 둔다. 실제 구현처럼 틀림이면 그 단어장의 노트에 넣는다(카드 학습은 노트에 넣지 않는다).
class FakeRecords implements StudyRecords {
  /// 카드를 넘겨 본 단어 id.
  final List<String> studied = [];
  final List<(String, bool)> quizzed = [];
  final List<WrongNote> notes = [];
  final List<String> removed = [];
  int _clock = 0;

  /// 시험 답: (단어장 id, 단어 id, 맞힘). 진도를 계산할 때 쓴다.
  final List<(String, String, bool)> _quizLog = [];

  /// 카드를 넘겨 본 단어장 id.
  final List<String> _cardDecks = [];

  /// 진도 화면에 돌려줄 집계(단어장 id별). 시험이 채운다. 없는 단어장은 기록으로 계산한다.
  final Map<String, Progress> progressValues = {};

  /// 실제 구현처럼 그 단어장 것만 센다: 외움 = 단어별 마지막 시험 답이 맞힘, 오답 = 노트 수,
  /// 날짜별 = 답이 있으면 오늘 하루.
  @override
  Future<Progress> progress(Deck deck) async {
    if (progressValues[deck.id] case final p?) return p;
    final last = <String, bool>{};
    for (final (d, w, ok) in _quizLog) {
      if (d == deck.id) last[w] = ok;
    }
    final cards = _cardDecks.where((d) => d == deck.id).length;
    final answered = _quizLog.where((e) => e.$1 == deck.id).length;
    return Progress(
      memorized: last.values.where((ok) => ok).length,
      wrong: notes.where((n) => n.deck.id == deck.id).length,
      days: [
        if (cards + answered > 0)
          DayStat(
            day: dayKey(DateTime.now()),
            cards: cards,
            answered: answered,
            correct: _quizLog.where((e) => e.$1 == deck.id && e.$3).length,
          ),
      ],
    );
  }

  /// 단어장을 지울 때: 그 단어장의 노트·학습·시험 기록을 지운다.
  void removeDeckRecords(String deckId) {
    notes.removeWhere((n) => n.deck.id == deckId);
    _quizLog.removeWhere((e) => e.$1 == deckId);
    _cardDecks.removeWhere((d) => d == deckId);
  }

  void _miss(Deck deck, Word word) {
    final i = notes.indexWhere(
      (n) => n.deck.id == deck.id && n.wordId == word.id,
    );
    final count = i < 0 ? 1 : notes[i].missCount + 1;
    if (i >= 0) notes.removeAt(i);
    notes.add(
      WrongNote(
        wordId: word.id,
        deck: deck,
        missCount: count,
        lastMissedAt: ++_clock,
      ),
    );
  }

  @override
  Future<void> recordCardViewed({
    required Deck deck,
    required Word word,
  }) async {
    studied.add(word.id);
    _cardDecks.add(deck.id);
  }

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) async {
    quizzed.add((word.id, correct));
    _quizLog.add((deck.id, word.id, correct));
    if (!correct) _miss(deck, word);
  }

  @override
  Future<List<WrongNote>> deckWrongNotes(Deck deck) async => [
    for (final n in notes)
      if (n.deck.id == deck.id) n,
  ]..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));

  @override
  Future<void> removeWrongNote(Deck deck, String wordId) async {
    removed.add(wordId);
    notes.removeWhere((n) => n.deck.id == deck.id && n.wordId == wordId);
  }

  @override
  Future<void> restoreWrongNote(WrongNote note) async {
    notes.removeWhere(
      (n) => n.deck.id == note.deck.id && n.wordId == note.wordId,
    );
    notes.add(note);
  }
}

WrongNote fakeNote(String id, Deck deck, {int miss = 1, int at = 0}) =>
    WrongNote(wordId: id, deck: deck, missCount: miss, lastMissedAt: at);

/// 옛 공통 설정(7판 전, 읽기만 한다)을 메모리에 둔다. 값이 null이면 저장된 것이 없다.
class FakeLegacySettingsStore implements LegacySettingsStore {
  FakeLegacySettingsStore({this.cardCount, this.quizCount});

  int? cardCount;
  int? quizCount;

  @override
  Future<int?> loadCardCount() async => cardCount;

  @override
  Future<int?> loadQuizCount() async => quizCount;
}
