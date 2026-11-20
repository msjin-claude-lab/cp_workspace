import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
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

  void _miss(Cell cell, Word word) {
    final i = notes.indexWhere((n) => n.wordId == word.id);
    final count = i < 0 ? 1 : notes[i].missCount + 1;
    if (i >= 0) notes.removeAt(i);
    notes.add(
      WrongNote(
        wordId: word.id,
        cell: cell,
        missCount: count,
        lastMissedAt: ++_clock,
      ),
    );
  }

  @override
  Future<void> recordAnswer({
    required Cell cell,
    required Word word,
    required bool known,
  }) async {
    studied.add((word.id, known));
    if (!known) _miss(cell, word);
  }

  @override
  Future<void> recordQuizAnswer({
    required Cell cell,
    required Word word,
    required bool correct,
  }) async {
    quizzed.add((word.id, correct));
    if (!correct) _miss(cell, word);
  }

  @override
  Future<List<WrongNote>> wrongNotes(SchoolLevel level) async => [
    for (final n in notes)
      if (n.cell.level == level) n,
  ]..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));

  @override
  Future<void> removeWrongNote(String wordId) async {
    removed.add(wordId);
    notes.removeWhere((n) => n.wordId == wordId);
  }
}

WrongNote fakeNote(String id, Cell cell, {int miss = 1, int at = 0}) =>
    WrongNote(wordId: id, cell: cell, missCount: miss, lastMissedAt: at);
