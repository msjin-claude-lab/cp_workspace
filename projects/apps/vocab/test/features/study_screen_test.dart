import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

const _apple = Word(
  id: 'ee-001',
  word: 'apple',
  meaning: '사과',
  example: 'I eat an apple.',
  exampleMeaning: '나는 사과를 먹는다.',
);
const _book = Word(
  id: 'ee-002',
  word: 'book',
  meaning: '책',
  example: 'This is my book.',
  exampleMeaning: '이것은 내 책이다.',
);

class _FakeRepository implements WordRepository {
  _FakeRepository(this.words);

  final Map<Cell, List<Word>> words;

  @override
  Future<List<Word>> wordsOf(Cell cell) async => words[cell] ?? const [];
}

class _FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

class _FakeRecords implements StudyRecords {
  final List<(String, bool)> answers = [];

  /// 있으면 저장이 이것이 끝날 때까지 걸린다(느린 DB 흉내).
  Completer<void>? gate;

  /// true면 저장이 실패한다.
  bool fail = false;

  @override
  Future<void> recordAnswer({
    required Cell cell,
    required Word word,
    required bool known,
  }) async {
    answers.add((word.id, known));
    if (gate != null) await gate!.future;
    if (fail) throw StateError('db');
  }

  @override
  Future<void> recordQuizAnswer({
    required Cell cell,
    required Word word,
    required bool correct,
  }) => throw UnimplementedError('카드 학습은 시험 기록을 쓰지 않는다');

  /// 가짜 오답 노트(오답 다시 보기 시험용).
  final List<WrongNote> notes = [];

  @override
  Future<List<WrongNote>> wrongNotes(SchoolLevel level) async => [
    for (final n in notes)
      if (n.cell.level == level) n,
  ];

  /// 카드 학습은 노트에서 빼면 안 된다 — 불리면 남겨 두고 시험이 확인한다.
  final List<String> removed = [];

  @override
  Future<void> removeWrongNote(String wordId) async => removed.add(wordId);

  @override
  Future<Progress> progress() async => const Progress();
}

class _FixedCellStore implements CellStore {
  @override
  Future<Cell?> load() async => Cell.elementaryEasy;

  @override
  Future<void> save(Cell cell) async {}
}

void main() {
  late _FakeSpeaker speaker;
  late _FakeRecords records;

  /// 가짜 단어·발음·기록을 넣은 ProviderScope로 감싼다.
  Widget scoped(Widget child) => ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(
        _FakeRepository({
          Cell.elementaryEasy: [_apple, _book],
        }),
      ),
      speakerProvider.overrideWithValue(speaker),
      studyRecordsProvider.overrideWithValue(records),
      // 주소로 시작하면 첫 화면을 지나므로, 학교급을 골라 둔 것으로 한다
      cellStoreProvider.overrideWithValue(_FixedCellStore()),
    ],
    child: child,
  );

  setUp(() {
    speaker = _FakeSpeaker();
    records = _FakeRecords();
  });

  Future<void> pumpStudy(WidgetTester tester) async {
    await tester.pumpWidget(
      scoped(const MaterialApp(home: StudyScreen(cell: Cell.elementaryEasy))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('앞면에 영단어가 보이고 자동으로 한 번 발음한다', (tester) async {
    await pumpStudy(tester);

    expect(find.text('초등 [난이도 : 쉬움] - 카드 학습'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('사과'), findsNothing);
    expect(find.byKey(const ValueKey('study-known')), findsNothing);
    expect(speaker.spoken, ['apple']);

    await tester.tap(find.byKey(const ValueKey('study-speak')));
    await tester.pump();
    expect(speaker.spoken, ['apple', 'apple']);
  });

  testWidgets('카드를 누르면 뒷면에 뜻·예문·해석과 안다/모른다가 보인다', (tester) async {
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();

    expect(find.text('사과'), findsOneWidget);
    expect(find.text('I eat an apple.'), findsOneWidget);
    expect(find.text('나는 사과를 먹는다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('study-known')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-unknown')), findsOneWidget);
  });

  testWidgets('답하면 기록되고 다음 카드로, 끝나면 결과를 보여 준다', (tester) async {
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-unknown')));
    await tester.pumpAndSettle();

    expect(find.text('book'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('책'), findsNothing); // 다음 카드는 앞면부터
    expect(speaker.spoken, ['apple', 'book']);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-known')));
    await tester.pumpAndSettle();

    expect(records.answers, [('ee-001', false), ('ee-002', true)]);
    expect(find.text('안다 1 · 모른다 1'), findsOneWidget);
    expect(find.text("'모른다' 단어는 오답 노트에 담았습니다"), findsOneWidget);

    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('학습 주소로 가면 그 칸의 학습 화면이 열린다', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(scoped(MaterialApp.router(routerConfig: router)));
    router.go('/study/elementary_easy');
    await tester.pumpAndSettle();

    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('저장 중에 연타해도 한 번만 기록되고 카드가 건너뛰지 않는다', (tester) async {
    records.gate = Completer<void>();
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-known')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-known')));
    await tester.pump();

    records.gate!.complete();
    await tester.pumpAndSettle();

    expect(records.answers, [('ee-001', true)]);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('저장에 실패하면 알리고 다음 카드로 가며, 결과에 실패를 밝힌다', (tester) async {
    records.fail = true;
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-unknown')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('study-save-error')), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-unknown')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('study-save-failed')), findsOneWidget);
    expect(find.text("'모른다' 단어는 오답 노트에 담았습니다"), findsNothing);
  });

  testWidgets('오답 다시 보기는 그 칸의 오답 노트 단어만 보여 준다', (tester) async {
    records.notes.add(
      const WrongNote(
        wordId: 'ee-002',
        cell: Cell.elementaryEasy,
        missCount: 1,
        lastMissedAt: 0,
      ),
    );
    await tester.pumpWidget(
      scoped(
        const MaterialApp(
          home: StudyScreen(cell: Cell.elementaryEasy, review: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('초등 [난이도 : 쉬움] - 오답 다시 보기'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('book'), findsOneWidget);
    expect(find.text('apple'), findsNothing);

    // '안다'로 답해도 오답 노트에서 빼지 않는다(빠지는 것은 오답 시험에서 맞혔을 때만)
    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-known')));
    await tester.pumpAndSettle();

    expect(records.answers, [('ee-002', true)]);
    expect(records.removed, isEmpty);
    expect(find.byKey(const ValueKey('study-save-failed')), findsNothing);
    expect(find.text('오답 노트에서 빼려면 오답 시험에서 맞히세요'), findsOneWidget);
  });

  testWidgets('없는 칸 주소는 안내만 보인다', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(scoped(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    router.go('/study/nope');
    await tester.pumpAndSettle();

    expect(find.text('없는 칸입니다'), findsOneWidget);
  });

  test('날짜 키는 기기 시간대의 YYYY-MM-DD', () {
    expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(dayKey(DateTime(2026, 11, 20)), '2026-11-20');
  });

  test('칸 id로 칸을 찾고, 없는 id는 null', () {
    expect(Cell.byId('high_medium'), Cell.highMedium);
    expect(Cell.byId('nope'), isNull);
  });
}
