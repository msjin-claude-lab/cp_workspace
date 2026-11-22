import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_books.dart';
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

  testWidgets('처음 실행하면 학교급 → 난이도를 세로로 고르고, 고른 칸이 저장되어 그 칸 홈이 열린다', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(find.text('영단어'), findsOneWidget); // 제목은 앱 이름
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

    expect(store.saved, Cell.middleHard);
    expect(find.byType(CellHomeScreen), findsOneWidget);
    expect(find.text('중등 [난이도 : 어려움]'), findsOneWidget);
    expect(find.text('4단어'), findsOneWidget);
    expect(find.text('시험'), findsOneWidget); // 문항 수는 보이지 않는다
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
  });

  testWidgets('저장된 칸이 있으면 앱을 열자마자 그 칸 홈이 보이고, 오답 수도 보인다', (tester) async {
    store.saved = Cell.elementaryEasy;
    records.notes.add(fakeNote('ee-002', Cell.elementaryEasy));
    await pumpApp(tester);

    expect(find.byType(LevelPickerScreen), findsNothing);
    expect(find.text('초등 [난이도 : 쉬움]'), findsOneWidget);
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });

  testWidgets('☰ 메뉴에는 앱 제목·버전과 등록한 학교급+난이도만 있고, 동그란 버튼으로 새로 등록하면 목록에 더해진다', (
    tester,
  ) async {
    store.saved = Cell.elementaryEasy; // 등록 목록이 없던 버전에서 고른 칸 → 등록된 것으로 본다
    await pumpApp(tester);

    await tap(tester, 'menu');
    // 메뉴 맨 위에 앱 제목과 그보다 작은 글씨의 버전
    final title = tester.widget<Text>(find.byKey(const ValueKey('menu-title')));
    final span = title.textSpan! as TextSpan;
    final version = span.children!.single as TextSpan;
    expect(span.toPlainText(), '영단어 v1.0.0');
    expect(version.style!.fontSize!, lessThan(span.style!.fontSize!));

    // 메뉴에는 등록한 것만 — 등록 버튼·메인화면·내 단어장·소제목은 없다
    expect(find.text('새 단어장'), findsNothing);
    expect(find.text('메인화면'), findsNothing);
    expect(find.text('내 단어장'), findsNothing);
    expect(find.text('기본 단어장'), findsNothing);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('menu-cell-elementary_easy')),
          )
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('menu-cell-high_easy')), findsNothing);

    // 메뉴를 닫고(바깥을 눌러) 동그란 버튼(글쓰기 아이콘) → 학교급 → 난이도로 등록한다
    await tester.tapAt(const Offset(780, 300));
    await tester.pumpAndSettle();
    expect(find.byTooltip('새 등록'), findsOneWidget);
    await tap(tester, 'home-register');
    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget); // 그만두고 돌아갈 수 있다
    await tap(tester, 'pick-high');
    await tap(tester, 'pick-high_easy');

    // 등록한 것이 홈이 되고 저장되며, 메뉴에 둘 다 보인다
    expect(store.saved, Cell.highEasy);
    expect(store.registered, [Cell.elementaryEasy, Cell.highEasy]);
    expect(find.text('고등 [난이도 : 쉬움]'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    await tap(tester, 'menu');
    expect(find.byKey(const ValueKey('menu-cell-high_easy')), findsOneWidget);

    // 목록의 다른 것을 누르면 그것이 홈이 된다
    await tap(tester, 'menu-cell-elementary_easy');
    expect(store.saved, Cell.elementaryEasy);
    expect(find.text('초등 [난이도 : 쉬움]'), findsOneWidget);
    // 같은 것을 다시 등록해도 목록이 늘지 않는다
    await tap(tester, 'home-register');
    await tap(tester, 'pick-high');
    await tap(tester, 'pick-high_easy');
    expect(store.registered, [Cell.elementaryEasy, Cell.highEasy]);
  });

  testWidgets('메뉴에서 등록한 것을 빠르게 두 번 눌러도 홈이 닫히지 않는다', (tester) async {
    store.saved = Cell.elementaryEasy;
    store.registered = [Cell.elementaryEasy, Cell.elementaryMedium];
    await pumpApp(tester);

    await tap(tester, 'menu');
    final item = find.byKey(const ValueKey('menu-cell-elementary_medium'));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50)); // 메뉴가 닫히는 중
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('초등 [난이도 : 중간]'), findsOneWidget);
    expect(find.byType(CellHomeScreen), findsOneWidget);
  });

  testWidgets('칸 저장에 실패해도 이번 실행에서는 고른 칸으로 보이고 실패를 알린다', (tester) async {
    store.fail = true;
    await pumpApp(tester);

    await tap(tester, 'pick-elementary');
    await tap(tester, 'pick-elementary_easy');

    expect(find.text('초등 [난이도 : 쉬움]'), findsOneWidget);
    expect(find.textContaining('저장하지 못했습니다'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('칸 홈에서 학습·시험·오답 노트를 열고, 안쪽 화면의 ← 뒤로로 칸 홈에 돌아온다', (tester) async {
    store.saved = Cell.elementaryEasy;
    await pumpApp(tester);

    await tap(tester, 'home-study');
    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('홈으로'), findsNothing); // 안쪽 화면에 홈으로 버튼은 없다
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CellHomeScreen), findsOneWidget);

    await tap(tester, 'home-quiz');
    expect(find.byType(QuizScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CellHomeScreen), findsOneWidget);

    await tap(tester, 'home-wrong');
    expect(find.byType(WrongNotesScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 오른쪽 아래 동그란 버튼은 새 등록(글쓰기 아이콘). "메인화면" 버튼은 없다
    expect(find.byTooltip('새 등록'), findsOneWidget);
    expect(find.byTooltip('메인화면'), findsNothing);
    expect(find.text('메인화면'), findsNothing);
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
