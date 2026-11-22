import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_books.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';
import 'package:vocab/features/progress/progress_screen.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocab/router.dart';

import 'fakes.dart';

void main() {
  late FakeCellStore store;
  late FakeRecords records;
  late FakeStudyDecks decks;

  final words = {
    Cell.elementaryEasy: [
      fakeWord('ee-001', 'apple', '사과'),
      fakeWord('ee-002', 'book', '책'),
    ],
    Cell.middleHard: [
      for (var i = 0; i < 4; i++) fakeWord('mh-00$i', 'm$i', '뜻$i'),
    ],
    Cell.highEasy: [
      for (var i = 0; i < 5; i++) fakeWord('he-00$i', 'h$i', '고$i'),
    ],
  };

  setUp(() {
    store = FakeCellStore();
    records = FakeRecords();
    decks = FakeStudyDecks(records);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(store),
          studyRecordsProvider.overrideWithValue(records),
          studyDecksProvider.overrideWithValue(decks),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          wordBooksProvider.overrideWithValue(FakeWordBooks(records)),
        ],
        child: MaterialApp.router(routerConfig: createRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const ValueKey('book-name-field')), name);
    await tap(tester, 'book-name-save');
  }

  /// 홈에서 동그란 버튼(새 등록) → 이름 → 학교급 → 난이도로 단어장을 만든다.
  Future<void> register(
    WidgetTester tester,
    String name,
    SchoolLevel level,
    Cell cell,
  ) async {
    await tap(tester, 'home-register');
    await enterName(tester, name);
    await tap(tester, 'pick-${level.name}');
    await tap(tester, 'pick-${cell.id}');
  }

  /// 메뉴를 닫는다(바깥을 누른다).
  Future<void> closeMenu(WidgetTester tester) async {
    await tester.tapAt(const Offset(780, 300));
    await tester.pumpAndSettle();
  }

  testWidgets('처음 실행하면 시작 화면 → 이름 → 학교급 → 난이도로 첫 단어장을 만들고, 홈에 그 이름이 보인다', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.text('영단어'), findsOneWidget); // 제목은 앱 이름
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    await tap(tester, 'start-create');
    await enterName(tester, '  아침 단어  '); // 앞뒤 공백은 뗀다

    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(find.text('어느 단계를 공부할까요?'), findsOneWidget);
    // 세로: 초등·중등·고등 버튼이 위에서 아래로
    final y = [
      for (final level in SchoolLevel.values)
        tester.getTopLeft(find.byKey(ValueKey('pick-${level.name}'))).dy,
    ];
    expect(y[0] < y[1] && y[1] < y[2], isTrue);

    await tap(tester, 'pick-middle');
    expect(find.byType(DifficultyPickerScreen), findsOneWidget);
    expect(find.text('난이도를 골라 주세요'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pick-middle_hard')),
        matching: find.text('4단어'),
      ),
      findsOneWidget,
    );

    await tap(tester, 'pick-middle_hard');

    expect(decks.list.map((d) => (d.name, d.base)), [
      ('아침 단어', Cell.middleHard),
    ]);
    expect(store.selectedDeck, decks.list.single.deckId);
    expect(find.byType(DeckHomeScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing); // 고르는 화면은 쌓이지 않는다
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('아침 단어')),
      findsOneWidget,
    );
    expect(find.text('중등 [난이도 : 어려움]'), findsOneWidget);
    expect(find.text('4단어'), findsOneWidget);
    expect(find.text('시험'), findsOneWidget); // 문항 수는 보이지 않는다
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
  });

  testWidgets('이름 창 취소, 학교급·난이도에서 ← 뒤로로 그만두면 아무것도 만들지 않는다', (tester) async {
    await pumpApp(tester);

    await tap(tester, 'start-create');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(StartScreen), findsOneWidget);

    // 빈 이름은 저장되지 않는다
    await tap(tester, 'start-create');
    await enterName(tester, '   ');
    expect(find.text('이름을 입력하세요'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tap(tester, 'start-create');
    await enterName(tester, '그만둘 것');
    await tester.pageBack(); // 학교급에서 뒤로
    await tester.pumpAndSettle();
    expect(find.byType(StartScreen), findsOneWidget);

    await tap(tester, 'start-create');
    await enterName(tester, '그만둘 것');
    await tap(tester, 'pick-high');
    await tester.pageBack(); // 난이도에서 뒤로
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(StartScreen), findsOneWidget);
    expect(decks.list, isEmpty);
    expect(store.selectedDeck, isNull);
  });

  testWidgets('난이도를 빠르게 두 번 눌러도 단어장은 하나만 생긴다', (tester) async {
    await pumpApp(tester);
    await tap(tester, 'start-create');
    await enterName(tester, '하나만');
    await tap(tester, 'pick-high');

    final button = find.byKey(const ValueKey('pick-high_easy'));
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(decks.list, hasLength(1));
    expect(find.byType(DeckHomeScreen), findsOneWidget);
  });

  testWidgets('저장된 단어장이 있으면 앱을 열자마자 그 홈이 보이고, 오답 수도 보인다', (tester) async {
    decks.seed('다른 것', Cell.highEasy);
    final deck = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = deck.deckId;
    records.notes.add(fakeNote('ee-002', deck));
    records.notes.add(fakeNote('ee-001', Cell.elementaryEasy)); // 칸 기록은 안 센다
    await pumpApp(tester);

    expect(find.byType(StartScreen), findsNothing);
    expect(find.text('아침 단어'), findsOneWidget);
    expect(find.text('초등 [난이도 : 쉬움]'), findsOneWidget);
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });

  testWidgets('옛 버전에서 고른 칸이 있으면 첫 실행 때 그 칸의 단어장이 만들어져 홈이 된다', (tester) async {
    store.legacyCell = Cell.middleHard;
    store.legacyRegistered = [Cell.elementaryEasy, Cell.middleHard];
    await pumpApp(tester);

    expect(decks.list.map((d) => (d.name, d.base)), [
      ('초등 쉬움', Cell.elementaryEasy),
      ('중등 어려움', Cell.middleHard),
    ]);
    expect(store.selectedDeck, decks.list[1].deckId);
    expect(find.text('중등 어려움'), findsOneWidget);
    expect(find.text('중등 [난이도 : 어려움]'), findsOneWidget);
  });

  testWidgets('동그란 버튼으로 같은 학교급+난이도를 또 만들면 다른 단어장이 되고, 기록이 섞이지 않는다', (
    tester,
  ) async {
    final first = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = first.deckId;
    await pumpApp(tester);

    // 아침 단어에서 카드 하나를 모른다고 한다 → 오답 1
    await tap(tester, 'home-study');
    await tap(tester, 'study-card');
    await tap(tester, 'study-unknown');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);

    expect(find.byTooltip('새 등록'), findsOneWidget);
    await register(
      tester,
      '저녁 단어',
      SchoolLevel.elementary,
      Cell.elementaryEasy,
    );

    // 새 단어장이 생겨 홈이 되고, 기존 것이 열리지 않는다
    expect(decks.list.map((d) => d.name), ['아침 단어', '저녁 단어']);
    final second = decks.list[1];
    expect(second.id, isNot(first.id));
    expect(store.selectedDeck, second.deckId);
    expect(find.text('저녁 단어'), findsOneWidget);
    expect(find.text('초등 [난이도 : 쉬움]'), findsOneWidget);
    expect(find.text('2단어'), findsOneWidget);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    // 새 단어장의 오답 노트·진도에는 아침 단어의 기록이 없다
    await tap(tester, 'home-wrong');
    expect(find.text('저녁 단어 - 오답 노트'), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, 'home-progress');
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.text('저녁 단어 - 진도'), findsOneWidget);
    expect(find.text('아직 시작하지 않았습니다'), findsOneWidget);
    expect(find.text('외움 0/2 · 오답 0'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 아침 단어로 돌아가면 그 기록이 그대로다
    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-${first.deckId}');
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
    await tap(tester, 'home-progress');
    expect(find.text('아침 단어 - 진도'), findsOneWidget);
    expect(find.text('진행 1일차'), findsOneWidget);
    expect(find.text('외움 0/2 · 오답 1'), findsOneWidget);
  });

  testWidgets('☰ 메뉴에는 앱 제목·버전과 내 단어장만 이름으로 있고, 누르면 그것이 홈이 되어 저장된다', (
    tester,
  ) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    final b = decks.seed('고등 연습', Cell.highEasy);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    await tap(tester, 'menu');
    // 메뉴 맨 위에 앱 제목과 그보다 작은 글씨의 버전
    final title = tester.widget<Text>(find.byKey(const ValueKey('menu-title')));
    final span = title.textSpan! as TextSpan;
    final version = span.children!.single as TextSpan;
    expect(span.toPlainText(), '영단어 v1.0.0');
    expect(version.style!.fontSize!, lessThan(span.style!.fontSize!));

    // 메뉴에는 내 단어장만 — 메인화면·기본 단어장·내 단어장(/books)·새 단어장 버튼은 없다
    expect(find.text('새 단어장'), findsNothing);
    expect(find.text('메인화면'), findsNothing);
    expect(find.text('내 단어장'), findsNothing);
    expect(find.text('기본 단어장'), findsNothing);
    final tileA = find.byKey(ValueKey('menu-deck-${a.deckId}'));
    final tileB = find.byKey(ValueKey('menu-deck-${b.deckId}'));
    expect(tester.widget<ListTile>(tileA).selected, isTrue);
    expect(tester.widget<ListTile>(tileB).selected, isFalse);
    expect(
      find.descendant(of: tileA, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tileB, matching: find.text('고등 연습')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tileB, matching: find.text('고등 [난이도 : 쉬움]')),
      findsOneWidget,
    );

    await tap(tester, 'menu-deck-${b.deckId}');
    expect(store.selectedDeck, b.deckId);
    expect(find.text('고등 연습'), findsOneWidget);
    expect(find.text('5단어'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('메뉴에서 단어장을 빠르게 두 번 눌러도 홈이 닫히지 않는다', (tester) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    final b = decks.seed('중간 단어', Cell.elementaryMedium);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    await tap(tester, 'menu');
    final item = find.byKey(ValueKey('menu-deck-${b.deckId}'));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50)); // 메뉴가 닫히는 중
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('중간 단어'), findsOneWidget);
    expect(find.byType(DeckHomeScreen), findsOneWidget);
  });

  testWidgets('메뉴의 ⋮로 이름을 바꾸면 메뉴와 홈 제목이 바뀐다', (tester) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-more-${a.deckId}');
    await tap(tester, 'deck-rename');
    expect(find.text('이름 바꾸기'), findsOneWidget);
    await enterName(tester, '새벽 단어');

    expect(decks.list.single.name, '새벽 단어');
    expect(
      find.descendant(
        of: find.byKey(ValueKey('menu-deck-${a.deckId}')),
        matching: find.text('새벽 단어'),
      ),
      findsOneWidget,
    );
    await closeMenu(tester);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('새벽 단어')),
      findsOneWidget,
    );
    await tap(tester, 'home-quiz');
    expect(find.text('새벽 단어 - 시험'), findsOneWidget);
  });

  testWidgets('메뉴의 ⋮로 지우면 물어본 뒤 지우고, 지금 것을 지우면 다른 것이, 모두 지우면 시작 화면이 된다', (
    tester,
  ) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    final b = decks.seed('저녁 단어', Cell.elementaryEasy);
    final c = decks.seed('고등 연습', Cell.highEasy);
    store.selectedDeck = b.deckId;
    records.notes.addAll([fakeNote('ee-001', a), fakeNote('ee-001', b)]);
    await pumpApp(tester);

    Future<void> delete(StudyDeck deck, {bool confirm = true}) async {
      await tap(tester, 'menu-deck-more-${deck.deckId}');
      await tap(tester, 'deck-delete');
      expect(find.textContaining(deck.name), findsWidgets);
      if (confirm) {
        await tap(tester, 'confirm-delete');
      } else {
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
      }
    }

    await tap(tester, 'menu');
    // 취소하면 그대로
    await delete(c, confirm: false);
    expect(decks.list, hasLength(3));

    // 지금 것이 아닌 것(고등 연습)을 지운다 — 홈은 그대로
    await delete(c);
    expect(decks.list.map((d) => d.name), ['아침 단어', '저녁 단어']);
    expect(find.byKey(ValueKey('menu-deck-${c.deckId}')), findsNothing);
    expect(store.selectedDeck, b.deckId);

    // 지금 것(저녁 단어)을 지우면 그 오답 노트만 지워지고 남은 것(아침 단어)이 홈이 된다
    await delete(b);
    expect(records.notes.map((n) => n.deck), [a]);
    expect(store.selectedDeck, a.deckId);
    await closeMenu(tester);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('아침 단어')),
      findsOneWidget,
    );
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);

    // 마지막 것을 지우면 시작 화면
    await tap(tester, 'menu');
    await delete(a);
    expect(decks.list, isEmpty);
    expect(find.byType(StartScreen), findsOneWidget);

    // 시작 화면에서 다시 만들 수 있다
    await tap(tester, 'start-create');
    await enterName(tester, '다시 시작');
    await tap(tester, 'pick-elementary');
    await tap(tester, 'pick-elementary_easy');
    expect(find.text('다시 시작'), findsOneWidget);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
  });

  testWidgets('고른 단어장 저장에 실패해도 이번 실행에서는 고른 것으로 보이고 실패를 알린다', (tester) async {
    store.fail = true;
    await pumpApp(tester);

    await tap(tester, 'start-create');
    await enterName(tester, '아침 단어');
    await tap(tester, 'pick-elementary');
    await tap(tester, 'pick-elementary_easy');

    expect(find.text('아침 단어'), findsOneWidget);
    expect(find.textContaining('저장하지 못했습니다'), findsOneWidget);
    expect(store.selectedDeck, isNull);
  });

  testWidgets('홈에서 학습·시험·오답 노트를 열고 제목은 단어장 이름이며, ← 뒤로로 홈에 돌아온다', (
    tester,
  ) async {
    final deck = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = deck.deckId;
    await pumpApp(tester);

    await tap(tester, 'home-study');
    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('아침 단어 - 카드 학습'), findsOneWidget);
    expect(find.text('홈으로'), findsNothing); // 안쪽 화면에 홈으로 버튼은 없다
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DeckHomeScreen), findsOneWidget);

    await tap(tester, 'home-quiz');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('아침 단어 - 시험'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DeckHomeScreen), findsOneWidget);

    await tap(tester, 'home-wrong');
    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(find.text('아침 단어 - 오답 노트'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tap(tester, 'home-progress');
    expect(find.text('아침 단어 - 진도'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 오른쪽 아래 동그란 버튼은 새 등록(글쓰기 아이콘). "메인화면" 버튼은 없다
    expect(find.byTooltip('새 등록'), findsOneWidget);
    expect(find.byIcon(Icons.edit_square), findsOneWidget);
    expect(find.byTooltip('메인화면'), findsNothing);
    expect(find.text('메인화면'), findsNothing);
  });

  testWidgets('카드 학습에서 모른다를 누르고 돌아오면 홈의 오답 수가 바로 바뀐다', (tester) async {
    final deck = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = deck.deckId;
    await pumpApp(tester);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    await tap(tester, 'home-study');
    await tap(tester, 'study-card');
    await tap(tester, 'study-unknown');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
    expect(records.notes.single.deck, deck);
  });
}
