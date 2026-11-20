import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocab/router.dart';

import 'fakes.dart';

void main() {
  late FakeCellStore store;
  late FakeRecords records;

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
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(store),
          studyRecordsProvider.overrideWithValue(records),
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

  testWidgets('처음 실행하면 학교급 → 난이도를 세로로 고르고, 고른 칸이 저장되어 그 칸 홈이 열린다', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(LevelPickerScreen), findsOneWidget);
    // 세로: 초등·중등·고등 버튼이 위에서 아래로
    final y = [
      for (final level in SchoolLevel.values)
        tester.getTopLeft(find.byKey(ValueKey('pick-${level.name}'))).dy,
    ];
    expect(y[0] < y[1] && y[1] < y[2], isTrue);

    await tap(tester, 'pick-middle');
    expect(find.byType(DifficultyPickerScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pick-middle_hard')),
        matching: find.text('4단어'),
      ),
      findsOneWidget,
    );

    await tap(tester, 'pick-middle_hard');

    expect(store.saved, Cell.middleHard);
    expect(find.byType(CellHomeScreen), findsOneWidget);
    expect(find.text('중등 · 상'), findsOneWidget);
    expect(find.text('4단어'), findsOneWidget);
    expect(find.text('4지선다 시험'), findsOneWidget); // 문항 수는 보이지 않는다
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
  });

  testWidgets('저장된 칸이 있으면 앱을 열자마자 그 칸 홈이 보이고, 오답 수도 보인다', (tester) async {
    store.saved = Cell.elementaryEasy;
    records.notes.add(fakeNote('ee-002', Cell.elementaryEasy));
    await pumpApp(tester);

    expect(find.byType(LevelPickerScreen), findsNothing);
    expect(find.text('초등 · 하'), findsOneWidget);
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });

  testWidgets('☰ 메뉴는 학교급 ▸ 난이도 2단계로 칸을 바꾸고, 바꾼 칸이 저장된다', (tester) async {
    store.saved = Cell.elementaryEasy;
    await pumpApp(tester);

    await tap(tester, 'menu');
    // 지금 학교급(초등)은 펼쳐져 있다
    expect(
      find.byKey(const ValueKey('menu-cell-elementary_hard')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('menu-cell-high_easy')), findsNothing);

    await tap(tester, 'menu-level-high');
    await tap(tester, 'menu-cell-high_easy');

    expect(store.saved, Cell.highEasy);
    expect(find.text('고등 · 하'), findsOneWidget);
    expect(find.text('5단어'), findsOneWidget);
  });

  testWidgets('메뉴에서 칸을 빠르게 두 번 눌러도 칸 홈이 닫히지 않는다', (tester) async {
    store.saved = Cell.elementaryEasy;
    await pumpApp(tester);

    await tap(tester, 'menu');
    final item = find.byKey(const ValueKey('menu-cell-elementary_medium'));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50)); // 메뉴가 닫히는 중
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('초등 · 중'), findsOneWidget);
    expect(find.byType(CellHomeScreen), findsOneWidget);
  });

  testWidgets('칸 저장에 실패해도 이번 실행에서는 고른 칸으로 보이고 실패를 알린다', (tester) async {
    store.fail = true;
    await pumpApp(tester);

    await tap(tester, 'pick-elementary');
    await tap(tester, 'pick-elementary_easy');

    expect(find.text('초등 · 하'), findsOneWidget);
    expect(find.textContaining('저장하지 못했습니다'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('칸 홈에서 학습·시험·오답 노트를 열고, 안쪽 화면의 ⌂ 홈과 ← 뒤로로 칸 홈에 돌아온다', (
    tester,
  ) async {
    store.saved = Cell.elementaryEasy;
    await pumpApp(tester);

    await tap(tester, 'home-study');
    expect(find.byType(StudyScreen), findsOneWidget);
    await tap(tester, 'go-home');
    expect(find.byType(CellHomeScreen), findsOneWidget);

    await tap(tester, 'home-quiz');
    expect(find.byType(QuizScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CellHomeScreen), findsOneWidget);

    await tap(tester, 'home-wrong');
    expect(find.byType(WrongNotesScreen), findsOneWidget);
    await tap(tester, 'go-home');

    // 칸 바꾸기 → 학교급 → 난이도 → 새 칸 홈(뒤로 쌓이지 않고 홈 하나만)
    await tap(tester, 'home-change');
    expect(find.byType(LevelPickerScreen), findsOneWidget);
    await tap(tester, 'pick-high');
    await tap(tester, 'pick-high_easy');
    expect(find.text('고등 · 하'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('카드 학습에서 모른다를 누르고 돌아오면 칸 홈의 오답 수가 바로 바뀐다', (tester) async {
    store.saved = Cell.elementaryEasy;
    await pumpApp(tester);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    await tap(tester, 'home-study');
    await tap(tester, 'study-card');
    await tap(tester, 'study-unknown');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });
}
