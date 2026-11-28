import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

import 'package:vocab/features/quiz/quiz.dart' show quizRandomProvider;

import '../fakes.dart'
    show FakeLegacySettingsStore, FakeCellStore, FakeStudyDecks, NoShuffleRandom;

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
  /// 넘겨 본 카드 단어 id.
  final List<String> viewed = [];

  /// 기록을 남긴 단어장 id(기록 주소가 맞는지 본다).
  final List<String> decks = [];

  /// 있으면 저장이 이것이 끝날 때까지 걸린다(느린 DB 흉내).
  Completer<void>? gate;

  /// true면 저장이 실패한다.
  bool fail = false;

  @override
  Future<void> recordCardViewed({
    required Deck deck,
    required Word word,
  }) async {
    viewed.add(word.id);
    decks.add(deck.id);
    if (gate != null) await gate!.future;
    if (fail) throw StateError('db');
  }

  /// 이미 넘겨 본 것으로 돌려줄 단어 id(안 본 단어 먼저 뽑기를 볼 때 채운다).
  Set<String> seen = {};

  /// true면 넘겨 본 기록 읽기가 실패한다. 실제 DB 오류처럼 Exception을 던진다 —
  /// Riverpod은 Exception이면 다시 시도하고(그동안 오류를 든 로딩), Error면 바로 AsyncError가 된다.
  bool failViewed = false;

  @override
  Future<Set<String>> viewedWordIds(Deck deck) async =>
      failViewed ? throw Exception('db') : seen;

  @override
  Future<Map<String, int>> lastViewedTimes(Deck deck) async => {
    for (final id in seen) id: 0,
  };

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) => throw UnimplementedError('카드 학습은 시험 기록을 쓰지 않는다');

  /// 가짜 오답 노트(카드 학습이 건드리지 않는지 본다).
  final List<WrongNote> notes = [];

  @override
  Future<List<WrongNote>> deckWrongNotes(Deck deck) async => [
    for (final n in notes)
      if (n.deck.id == deck.id) n,
  ];

  /// 카드 학습은 노트를 바꾸면 안 된다 — 불리면 남겨 두고 시험이 확인한다.
  final List<String> removed = [];

  @override
  Future<void> removeWrongNote(Deck deck, String wordId) async =>
      removed.add(wordId);

  @override
  Future<void> restoreWrongNote(WrongNote note) async => notes.add(note);

  @override
  Future<Progress> progress(Deck deck) async => const Progress();
}

void main() {
  late _FakeSpeaker speaker;
  late _FakeRecords records;

  /// 가짜 단어·발음·기록을 넣은 ProviderScope로 감싼다.
  Widget scoped(Widget child) => ProviderScope(
    overrides: [
      legacySettingsStoreProvider.overrideWithValue(FakeLegacySettingsStore()),
      wordRepositoryProvider.overrideWithValue(
        _FakeRepository({
          Cell.elementaryEasy: [_apple, _book],
        }),
      ),
      speakerProvider.overrideWithValue(speaker),
      studyRecordsProvider.overrideWithValue(records),
      // 카드는 무작위 순서로 나온다 — 순서를 확인하는 시험이라 섞이지 않게 한다
      quizRandomProvider.overrideWithValue(NoShuffleRandom()),
      // 주소로 시작하면 첫 화면을 지나므로, 단어장을 만들어 골라 둔 것으로 한다
      cellStoreProvider.overrideWithValue(FakeCellStore(selectedDeck: 1)),
      studyDecksProvider.overrideWithValue(
        FakeStudyDecks()..seed('아침 단어', Cell.elementaryEasy),
      ),
    ],
    child: child,
  );

  setUp(() {
    speaker = _FakeSpeaker();
    records = _FakeRecords();
  });

  Future<void> pumpStudy(WidgetTester tester) async {
    await tester.pumpWidget(
      scoped(const MaterialApp(home: StudyScreen(deck: Cell.elementaryEasy))),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('앞면에 영단어가 보이고 자동으로 한 번 발음하며, 이전/다음이 늘 보인다', (tester) async {
    await pumpStudy(tester);

    expect(find.text('초등 [난이도 : 쉬움] - 카드 학습'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('사과'), findsNothing);
    expect(find.byKey(const ValueKey('study-next')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-previous')), findsOneWidget);
    expect(find.text('안다'), findsNothing);
    expect(find.text('모른다'), findsNothing);
    expect(speaker.spoken, ['apple']);

    await tester.tap(find.byKey(const ValueKey('study-speak')));
    await tester.pump();
    expect(speaker.spoken, ['apple', 'apple']);
  });

  testWidgets('첫 카드에서도 진행 막대가 숫자(1 / 2)만큼 차 있다', (tester) async {
    await pumpStudy(tester);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.5);
  });

  testWidgets('뒷면의 발음 버튼은 다시 읽어 주고 카드를 뒤집지 않는다', (tester) async {
    await pumpStudy(tester);
    expect(find.byKey(const ValueKey('study-speak-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-speak-back')));
    await tester.pump();

    expect(speaker.spoken, ['apple', 'apple']);
    expect(find.text('사과'), findsOneWidget); // 아직 뒷면
  });

  testWidgets('가로로 낮은 화면에서도 뒷면이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('사과'), findsOneWidget);
  });

  testWidgets('카드를 누르면 뒷면에 뜻·예문·해석이 보이고, 다시 누르면 앞면으로 돌아온다', (tester) async {
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    expect(find.text('사과'), findsOneWidget);
    expect(find.text('I eat an apple.'), findsOneWidget);
    expect(find.text('나는 사과를 먹는다.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    expect(find.text('사과'), findsNothing);
    expect(records.viewed, isEmpty); // 뒤집기만으로는 기록하지 않는다
  });

  testWidgets('이전은 첫 카드에서 막혀 있고, 다음·이전으로 옮기면 앞면이 보인다', (tester) async {
    await pumpStudy(tester);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('study-previous')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tapKey(tester, 'study-next');
    expect(find.text('book'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('책'), findsNothing); // 다음 카드는 앞면부터
    expect(speaker.spoken, ['apple', 'book']);

    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    expect(find.text('책'), findsOneWidget);
    await tapKey(tester, 'study-previous');
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('사과'), findsNothing);
    // 되돌아가도 기록은 늘지 않는다(넘긴 것은 apple 하나)
    expect(records.viewed, ['ee-001']);
  });

  testWidgets('다음으로 카드마다 한 번 기록하고, 끝나면 결과를 보여 주며, 오답 노트는 건드리지 않는다', (
    tester,
  ) async {
    await pumpStudy(tester);

    await tapKey(tester, 'study-next');
    await tapKey(tester, 'study-next');

    expect(records.viewed, ['ee-001', 'ee-002']);
    expect(find.text('2단어를 모두 봤습니다'), findsOneWidget);
    expect(find.textContaining('모른다'), findsNothing);
    expect(find.textContaining('오답 노트'), findsNothing);
    expect(find.text('오답 노트로'), findsNothing);
    expect(records.notes, isEmpty);
    expect(records.removed, isEmpty);

    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('이전으로 돌아갔다가 다시 다음을 눌러도 같은 카드는 한 회차에 한 번만 기록하고, 다시 하기 뒤에는 새로 센다', (
    tester,
  ) async {
    await pumpStudy(tester);

    await tapKey(tester, 'study-next');
    await tapKey(tester, 'study-previous');
    await tapKey(tester, 'study-next');
    expect(find.text('book'), findsOneWidget);
    expect(records.viewed, ['ee-001']);

    await tapKey(tester, 'study-next');
    expect(records.viewed, ['ee-001', 'ee-002']);

    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'study-next');
    expect(records.viewed, ['ee-001', 'ee-002', 'ee-001']);
  });

  /// 앞 화면에서 학습 화면을 밀어 올려 ← 뒤로가 되게 한다.
  Future<void> pumpPushedStudy(WidgetTester tester) async {
    await tester.pumpWidget(
      scoped(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const ValueKey('open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const StudyScreen(deck: Cell.elementaryEasy),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('첫 카드에서 아무것도 안 했으면 ← 뒤로는 묻지 않고 나간다', (tester) async {
    await pumpPushedStudy(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('그만할까요?'), findsNothing);
    expect(find.byType(StudyScreen), findsNothing);
  });

  testWidgets('도중에 ← 뒤로(앱바·시스템)를 누르면 먼저 묻고, 계속하기면 남고 나가기면 나간다', (tester) async {
    await pumpPushedStudy(tester);
    await tapKey(tester, 'study-next');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsOneWidget);
    expect(find.textContaining('처음부터'), findsOneWidget);
    await tapKey(tester, 'leave-continue');
    expect(find.text('그만할까요?'), findsNothing);
    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    // 시스템 뒤로도 같다
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsOneWidget);
    await tapKey(tester, 'leave-exit');
    expect(find.byType(StudyScreen), findsNothing);
    expect(records.viewed, ['ee-001']); // 지금까지 본 기록은 남아 있다
  });

  testWidgets('첫 카드라도 뒷면을 봤으면 묻고, 끝 화면에서는 묻지 않는다', (tester) async {
    await pumpPushedStudy(tester);
    await tester.tap(find.byKey(const ValueKey('study-card')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsOneWidget);
    await tapKey(tester, 'leave-continue');

    await tapKey(tester, 'study-next');
    await tapKey(tester, 'study-next');
    expect(find.text('2단어를 모두 봤습니다'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsNothing);
    expect(find.byType(StudyScreen), findsNothing);
  });

  testWidgets('한 번이라도 넘겼으면 이전으로 첫 카드 앞면에 돌아와도 묻고, 다시 하기 뒤에는 새 회차로 본다', (
    tester,
  ) async {
    await pumpPushedStudy(tester);
    await tapKey(tester, 'study-next');
    await tapKey(tester, 'study-previous');
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('사과'), findsNothing); // 앞면

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsOneWidget);
    await tapKey(tester, 'leave-continue');

    // 끝까지 보고 다시 하기 — 새 회차의 아무것도 안 한 첫 카드에서는 묻지 않는다
    await tapKey(tester, 'study-next');
    await tapKey(tester, 'study-next');
    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('그만할까요?'), findsNothing);
    expect(find.byType(StudyScreen), findsNothing);
  });

  testWidgets('학습 주소로 가면 그 칸의 학습 화면이 열린다', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(scoped(MaterialApp.router(routerConfig: router)));
    router.go('/study/elementary_easy');
    await tester.pumpAndSettle();

    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('단어장 주소(deck_1)로 가면 바탕 칸의 단어로 학습하고, 제목과 기록은 그 단어장 것이다', (
    tester,
  ) async {
    final router = createRouter();
    await tester.pumpWidget(scoped(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    router.go('/study/deck_1');
    await tester.pumpAndSettle();

    expect(find.text('아침 단어 - 카드 학습'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    await tapKey(tester, 'study-next');
    expect(records.decks, ['deck_1']);
  });

  testWidgets('저장 중에 연타해도 한 번만 기록되고 카드가 건너뛰지 않는다', (tester) async {
    records.gate = Completer<void>();
    await pumpStudy(tester);

    await tester.tap(find.byKey(const ValueKey('study-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('study-next')));
    await tester.pump();

    records.gate!.complete();
    await tester.pumpAndSettle();

    expect(records.viewed, ['ee-001']);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('저장에 실패하면 알리고 다음 카드로 가며, 결과에 실패를 밝힌다', (tester) async {
    records.fail = true;
    await pumpStudy(tester);

    await tapKey(tester, 'study-next');
    expect(find.byKey(const ValueKey('study-save-error')), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tapKey(tester, 'study-next');
    expect(find.byKey(const ValueKey('study-save-failed')), findsOneWidget);
  });

  testWidgets('카드는 회차마다 섞여 나오고, 한 회차 안에서는 이전/다음이 같은 순서를 오간다', (tester) async {
    final words = [
      for (var i = 0; i < 12; i++)
        Word(
          id: 'ee-1$i',
          word: 'w$i',
          meaning: 'm$i',
          example: '',
          exampleMeaning: '',
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legacySettingsStoreProvider.overrideWithValue(FakeLegacySettingsStore()),
          wordRepositoryProvider.overrideWithValue(
            _FakeRepository({Cell.elementaryEasy: words}),
          ),
          speakerProvider.overrideWithValue(speaker),
          studyRecordsProvider.overrideWithValue(records),
          quizRandomProvider.overrideWithValue(Random(3)),
        ],
        child: const MaterialApp(home: StudyScreen(deck: Cell.elementaryEasy)),
      ),
    );
    await tester.pumpAndSettle();

    String shown() => words
        .map((w) => w.word)
        .firstWhere((w) => find.text(w).evaluate().isNotEmpty);

    // 끝까지 넘기며 본 순서: 모든 단어가 한 번씩, 저장된 순서와는 다르게
    final seen = <String>[];
    for (var i = 0; i < words.length; i++) {
      seen.add(shown());
      if (i == 1) {
        // 이전으로 갔다 와도 같은 카드다
        await tester.tap(find.byKey(const ValueKey('study-previous')));
        await tester.pumpAndSettle();
        expect(shown(), seen[0]);
        await tester.tap(find.byKey(const ValueKey('study-next')));
        await tester.pumpAndSettle();
        expect(shown(), seen[1]);
      }
      await tester.tap(find.byKey(const ValueKey('study-next')));
      await tester.pumpAndSettle();
    }
    expect(seen.toSet(), {for (final w in words) w.word});
    expect(seen, isNot([for (final w in words) w.word]));

    // 다시 하기는 새로 섞는다
    await tester.tap(find.text('다시 하기'));
    await tester.pumpAndSettle();
    final again = <String>[];
    for (var i = 0; i < words.length; i++) {
      again.add(shown());
      await tester.tap(find.byKey(const ValueKey('study-next')));
      await tester.pumpAndSettle();
    }
    expect(again.toSet(), seen.toSet());
    expect(again, isNot(seen));
  });

  testWidgets('넘겨 본 기록이 카드 뽑기에 전달된다(섞지 않으면 안 본 단어가 앞)', (tester) async {
    records.seen = {_apple.id};
    await pumpStudy(tester);

    expect(find.text('book'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tapKey(tester, 'study-next');
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('넘겨 본 기록을 읽지 못해도 다시 시도를 기다리지 않고 카드 학습이 열린다', (tester) async {
    records.failViewed = true;
    await tester.pumpWidget(
      scoped(const MaterialApp(home: StudyScreen(deck: Cell.elementaryEasy))),
    );
    // 다시 시도(첫 간격 200ms)가 끝나기 전에 이미 카드가 보여야 한다
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    // 남은 다시 시도 타이머를 흘려보낸다(도중에 카드가 바뀌지 않는다)
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('다시 하기는 이번 화면에서 방금 본 단어를 뒤로 미룬다', (tester) async {
    const cat = Word(
      id: 'ee-003',
      word: 'cat',
      meaning: '고양이',
      example: 'I have a cat.',
      exampleMeaning: '나는 고양이가 있다.',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 한 회차에 카드 1장
          legacySettingsStoreProvider.overrideWithValue(
            FakeLegacySettingsStore(cardCount: 1),
          ),
          wordRepositoryProvider.overrideWithValue(
            _FakeRepository({
              Cell.elementaryEasy: [_apple, _book, cat],
            }),
          ),
          speakerProvider.overrideWithValue(speaker),
          studyRecordsProvider.overrideWithValue(records),
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
        ],
        child: const MaterialApp(home: StudyScreen(deck: Cell.elementaryEasy)),
      ),
    );
    await tester.pumpAndSettle();

    // DB에서 읽은 기록은 그대로인데(가짜는 seen을 늘리지 않는다) 회차마다 새 단어가 나온다
    for (final word in ['apple', 'book', 'cat']) {
      expect(find.text(word), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      await tapKey(tester, 'study-next');
      await tester.tap(find.text('다시 하기'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('없는 칸 주소는 안내만 보인다', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(scoped(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    router.go('/study/nope');
    await tester.pumpAndSettle();

    expect(find.text('찾을 수 없는 화면입니다'), findsOneWidget);
  });

  test('날짜 키는 기기 시간대의 YYYY-MM-DD', () {
    expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    expect(dayKey(DateTime(2026, 11, 20)), '2026-11-20');
  });

  test('칸 id로 칸을 찾고, 없는 id는 null', () {
    expect(Cell.byId('high_medium'), Cell.highMedium);
    expect(Cell.byId('nope'), isNull);
    // 이름 있는 단어장 id는 칸이 아니다
    expect(Cell.byId('deck_1'), isNull);
    expect(StudyDeck.parseId('deck_12'), 12);
    expect(StudyDeck.parseId('middle_medium'), isNull);
  });
}
