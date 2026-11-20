import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_books.dart';
import 'package:vocab/data/word_repository.dart';

/// 시험(test)에서 함께 쓰는 가짜들. 모두 메모리에만 둔다.

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

/// `saved`가 기기에 저장된 칸 역할.
class FakeCellStore implements CellStore {
  FakeCellStore([this.saved]);

  Cell? saved;
  bool fail = false;

  @override
  Future<Cell?> load() async => saved;

  @override
  Future<void> save(Cell cell) async {
    if (fail) throw StateError('prefs');
    saved = cell;
  }
}

class FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

/// 기록과 오답 노트를 메모리에 둔다. 실제 구현처럼 '모른다'·틀림이면 노트에 넣는다.
class FakeRecords implements StudyRecords {
  final List<(String, bool)> studied = [];
  final List<(String, bool)> quizzed = [];
  final List<WrongNote> notes = [];
  final List<String> removed = [];
  int _clock = 0;

  /// 진도 화면에 돌려줄 집계. 시험이 채운다.
  Progress progressValue = const Progress();

  @override
  Future<Progress> progress() async => progressValue;

  void _miss(Deck deck, Word word) {
    final i = notes.indexWhere((n) => n.wordId == word.id);
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
  Future<void> recordAnswer({
    required Deck deck,
    required Word word,
    required bool known,
  }) async {
    studied.add((word.id, known));
    if (!known) _miss(deck, word);
  }

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) async {
    quizzed.add((word.id, correct));
    if (!correct) _miss(deck, word);
  }

  /// 실제 구현처럼 내장 칸의 노트만 학교급으로 거른다(내 단어장 노트는 빠진다).
  @override
  Future<List<WrongNote>> wrongNotes(SchoolLevel level) async => [
    for (final n in notes)
      if (n.deck case Cell(level: final l) when l == level) n,
  ]..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));

  @override
  Future<List<WrongNote>> bookWrongNotes(BookDeck book) async => [
    for (final n in notes)
      if (n.deck == book) n,
  ]..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));

  @override
  Future<void> removeWrongNote(String wordId) async {
    removed.add(wordId);
    notes.removeWhere((n) => n.wordId == wordId);
  }
}

WrongNote fakeNote(String id, Deck deck, {int miss = 1, int at = 0}) =>
    WrongNote(wordId: id, deck: deck, missCount: miss, lastMissedAt: at);

/// 내 단어장을 메모리에 둔다. 단어 id는 실제 구현처럼 `bw-N`.
/// 지울 때 오답 노트도 지우는 것을 흉내 내려면 `records`를 준다.
class FakeWordBooks implements WordBooks {
  FakeWordBooks([this.records]);

  final FakeRecords? records;
  final Map<int, String> names = {};
  final Map<int, List<Word>> bookWords = {};
  int _nextBook = 1;
  int _nextWord = 1;

  /// 시험이 단어장을 미리 만들어 둘 때 쓴다. 번호를 돌려준다.
  int seed(String name, List<(String, String)> words) {
    final id = _nextBook++;
    names[id] = name;
    bookWords[id] = [
      for (final (w, m) in words)
        Word(
          id: bookWordId(_nextWord++),
          word: w,
          meaning: m,
          example: '',
          exampleMeaning: '',
        ),
    ];
    return id;
  }

  WordBook _book(int id) =>
      WordBook(id: id, name: names[id]!, wordCount: bookWords[id]!.length);

  @override
  Future<List<WordBook>> books() async => [
    for (final id in names.keys) _book(id),
  ];

  @override
  Future<WordBook?> book(int id) async =>
      names.containsKey(id) ? _book(id) : null;

  @override
  Future<int> createBook(String name) async => seed(name, const []);

  @override
  Future<void> renameBook(int id, String name) async => names[id] = name;

  @override
  Future<void> deleteBook(int id) async {
    final deckId = BookDeck(bookId: id, name: '').id;
    records?.notes.removeWhere((n) => n.deck.id == deckId);
    names.remove(id);
    bookWords.remove(id);
  }

  @override
  Future<List<Word>> words(int bookId) async => [...?bookWords[bookId]];

  @override
  Future<void> addWord(
    int bookId, {
    required String word,
    required String meaning,
    String example = '',
    String exampleMeaning = '',
  }) async {
    bookWords[bookId]!.add(
      Word(
        id: bookWordId(_nextWord++),
        word: word,
        meaning: meaning,
        example: example,
        exampleMeaning: exampleMeaning,
      ),
    );
  }

  @override
  Future<void> updateWord(Word word) async {
    for (final list in bookWords.values) {
      final i = list.indexWhere((w) => w.id == word.id);
      if (i >= 0) list[i] = word;
    }
  }

  @override
  Future<void> deleteWord(String wordId) async {
    records?.notes.removeWhere((n) => n.wordId == wordId);
    for (final list in bookWords.values) {
      list.removeWhere((w) => w.id == wordId);
    }
  }
}
