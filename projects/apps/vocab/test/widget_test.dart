import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';
import 'package:vocab/features/progress/progress_screen.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocab/router.dart';

import 'package:vocab/features/quiz/quiz.dart' show quizRandomProvider;

import 'fakes.dart';

void main() {
  late FakeCellStore store;
  late FakeLegacySettingsStore settingsStore;
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
    settingsStore = FakeLegacySettingsStore();
    records = FakeRecords();
    decks = FakeStudyDecks(records);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legacySettingsStoreProvider.overrideWithValue(settingsStore),
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(store),
          studyRecordsProvider.overrideWithValue(records),
          // 카드·시험은 무작위 순서 — 순서를 확인하는 시험이 있어 섞이지 않게 한다
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
          studyDecksProvider.overrideWithValue(decks),
          speakerProvider.overrideWithValue(FakeSpeaker()),
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
    expect(find.text('학교급을 고르세요'), findsOneWidget);
    expect(find.text('새 단어장 - 아침 단어'), findsOneWidget);
    // 세로: 초등·중등·고등 버튼이 위에서 아래로
    final y = [
      for (final level in SchoolLevel.values)
        tester.getTopLeft(find.byKey(ValueKey('pick-${level.name}'))).dy,
    ];
    expect(y[0] < y[1] && y[1] < y[2], isTrue);

    await tap(tester, 'pick-middle');
    expect(find.byType(DifficultyPickerScreen), findsOneWidget);
    expect(find.text('난이도를 고르세요'), findsOneWidget);
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
    // 아침 단어에는 시험에서 틀린 단어가 하나 있다 → 오답 1
    records.notes.add(fakeNote('ee-001', first));
    await records.recordCardViewed(
      deck: first,
      word: fakeWord('ee-001', 'apple', '사과'),
    );
    await pumpApp(tester);
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
    expect(find.text('외운 단어 0/2'), findsOneWidget);
    expect(find.text('오답 노트 0단어'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 아침 단어로 돌아가면 그 기록이 그대로다
    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-${first.deckId}');
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
    await tap(tester, 'home-progress');
    expect(find.text('아침 단어 - 진도'), findsOneWidget);
    expect(find.text('진행 1일차'), findsOneWidget);
    expect(find.text('외운 단어 0/2'), findsOneWidget);
    expect(find.text('오답 노트 1단어'), findsOneWidget);
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

    // 메뉴에는 내 단어장만 — 메인화면·기본 단어장·"내 단어장" 항목·새 단어장 버튼은 없다
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

  testWidgets('단어장 목록을 읽지 못하면 다시 시도 버튼이 있고, 누르면 다시 읽어 홈을 보여 준다', (
    tester,
  ) async {
    final flaky = _FlakyDecks(records);
    decks = flaky;
    final deck = flaky.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = deck.deckId;
    flaky.fail = true;
    await pumpApp(tester);

    expect(find.text('단어장을 읽지 못했습니다'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-retry')), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    flaky.fail = false;
    await tap(tester, 'home-retry');

    expect(find.text('단어장을 읽지 못했습니다'), findsNothing);
    expect(find.text('아침 단어'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-study')), findsOneWidget);
  });

  testWidgets('새 등록의 이름 창은 확인 버튼이 다음이고, 두 고르기 화면은 같은 제목과 안내 문구를 쓴다', (
    tester,
  ) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    await tap(tester, 'home-register');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('book-name-save')),
        matching: find.text('다음'),
      ),
      findsOneWidget,
    );
    expect(find.text('저장'), findsNothing);
    await enterName(tester, '쉬는 시간 단어');

    expect(find.text('새 단어장 - 쉬는 시간 단어'), findsOneWidget);
    expect(find.text('학교급을 고르세요'), findsOneWidget);
    await tap(tester, 'pick-middle');
    expect(find.text('새 단어장 - 쉬는 시간 단어'), findsOneWidget);
    expect(find.text('난이도를 고르세요'), findsOneWidget);
  });

  testWidgets('이름은 20자까지이고 글자 수가 보이며, 20자를 넘는 옛 이름도 보이고 고칠 수 있다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const long = '아주 아주 긴 단어장 이름을 스물 글자보다 훨씬 더 길게 지어 둔 것';
    expect(long.length, greaterThan(20));
    final a = decks.seed(long, Cell.elementaryEasy);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    // 긴 이름도 제목에 한 줄로 줄여 보이고, 메뉴 줄은 두 줄까지
    final title = tester.widget<Text>(
      find.descendant(of: find.byType(AppBar), matching: find.text(long)),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    await tap(tester, 'menu');
    final row = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('menu-deck-${a.deckId}')),
        matching: find.text(long),
      ),
    );
    expect(row.maxLines, 2);

    // 새 이름은 20자까지만 들어가고(넘치게 쳐도 잘림), 앞뒤 공백을 뗀다
    await tap(tester, 'menu-deck-more-${a.deckId}');
    await tap(tester, 'deck-rename');
    expect(find.text('저장'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('book-name-field')),
      '  ${'가' * 30}',
    );
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 20);
    expect(find.text('20/20'), findsOneWidget);
    // 빈 이름은 안 된다
    await tester.enterText(find.byKey(const ValueKey('book-name-field')), '  ');
    await tap(tester, 'book-name-save');
    expect(find.text('이름을 입력하세요'), findsOneWidget);
    await enterName(tester, '가나다');
    expect(decks.list.single.name, '가나다');
  });

  testWidgets('단어장 지우기 확인 창은 무엇이 사라지는지 알려 준다', (tester) async {
    final a = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = a.deckId;
    await pumpApp(tester);

    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-more-${a.deckId}');
    await tap(tester, 'deck-delete');

    expect(find.text('"아침 단어" 단어장을 지울까요?'), findsOneWidget);
    expect(find.text('이 단어장의 오답 노트와 진도 기록이 사라지고 되돌릴 수 없습니다'), findsOneWidget);
  });

  testWidgets('카드 학습을 하고 돌아와도 오답 노트에는 아무것도 담기지 않는다', (tester) async {
    final deck = decks.seed('아침 단어', Cell.elementaryEasy);
    store.selectedDeck = deck.deckId;
    await pumpApp(tester);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    await tap(tester, 'home-study');
    await tap(tester, 'study-next');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, 'leave-exit'); // 도중이라 묻는다

    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
    expect(records.notes, isEmpty);
    expect(records.studied, ['ee-001']);
  });

  /// 지금 문제에서 틀린 보기를 골라 답하고 다음으로 넘긴다.
  /// 단어는 `m<N>`·`뜻<N>`이라 문제 글자의 끝 숫자와 다른 보기가 오답이다.
  Future<void> answerWrong(WidgetTester tester) async {
    final prompt = tester
        .widget<Text>(find.byKey(const ValueKey('quiz-prompt')))
        .data!;
    final n = prompt[prompt.length - 1];
    for (var i = 0; i < 4; i++) {
      final option = find.byKey(ValueKey('quiz-option-$i'));
      final text = tester
          .widget<Text>(
            find.descendant(of: option, matching: find.byType(Text)),
          )
          .data!;
      if (text.endsWith(n)) continue;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      break;
    }
    await tester.ensureVisible(find.byKey(const ValueKey('quiz-next')));
    await tap(tester, 'quiz-next');
  }

  /// 홈에서 시험을 열어 4문제를 모두 틀리고 결과 화면까지 간다.
  Future<void> failWholeQuiz(WidgetTester tester) async {
    final deck = decks.seed('저녁 단어', Cell.middleHard);
    store.selectedDeck = deck.deckId;
    await pumpApp(tester);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    await tap(tester, 'home-quiz');
    for (var i = 0; i < 4; i++) {
      await answerWrong(tester);
    }
    expect(find.text('4문제 중 0문제 맞혔습니다'), findsOneWidget);
    expect(records.notes, hasLength(4));
  }

  testWidgets('시험을 마치고 오답 노트 보기를 누르면 방금 틀린 단어가 노트에 있고, 홈의 오답 수도 맞다', (
    tester,
  ) async {
    await failWholeQuiz(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('quiz-to-notes')));
    await tap(tester, 'quiz-to-notes');

    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(find.text('오답 노트가 비어 있습니다'), findsNothing);
    for (var i = 0; i < 4; i++) {
      expect(find.textContaining('m$i'), findsWidgets);
    }

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DeckHomeScreen), findsOneWidget);
    expect(find.text('오답 노트 · 4단어'), findsOneWidget);
  });

  testWidgets('시험을 마치고 홈으로를 누르면 홈의 오답 수가 방금 틀린 만큼 늘어 있다', (tester) async {
    await failWholeQuiz(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('quiz-home')));
    await tap(tester, 'quiz-home');

    expect(find.byType(DeckHomeScreen), findsOneWidget);
    expect(find.text('오답 노트 · 4단어'), findsOneWidget);
  });
}

/// `fail`이 true인 동안 단어장 목록 읽기가 실패한다.
class _FlakyDecks extends FakeStudyDecks {
  _FlakyDecks(super.records);

  bool fail = false;

  @override
  Future<List<StudyDeck>> decks() async {
    if (fail) throw StateError('db');
    return super.decks();
  }
}
