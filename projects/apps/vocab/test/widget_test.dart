import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/level_store.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

/// 칸마다 정해 둔 개수의 단어를 돌려주는 가짜 저장소.
class _FakeRepository implements WordRepository {
  _FakeRepository(this.counts);

  final Map<Cell, int> counts;

  @override
  Future<List<Word>> wordsOf(Cell cell) async => [
    for (var i = 0; i < (counts[cell] ?? 0); i++)
      Word(
        id: '$i',
        word: 'w$i',
        meaning: 'm$i',
        example: 'e$i',
        exampleMeaning: 'em$i',
      ),
  ];
}

/// 메모리에만 남기는 학교급 저장소. `saved`가 기기에 저장된 값 역할.
class _FakeLevelStore implements LevelStore {
  _FakeLevelStore([this.saved]);

  SchoolLevel? saved;
  bool fail = false;

  @override
  Future<SchoolLevel?> load() async => saved;

  @override
  Future<void> save(SchoolLevel level) async {
    if (fail) throw StateError('prefs');
    saved = level;
  }
}

void main() {
  late _FakeLevelStore store;

  Widget app(Widget child) => ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(
        _FakeRepository({
          Cell.elementaryEasy: 2,
          Cell.middleHard: 4,
          Cell.highHard: 5,
        }),
      ),
      levelStoreProvider.overrideWithValue(store),
    ],
    child: child,
  );

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(app(const MaterialApp(home: HomeScreen())));
    await tester.pumpAndSettle();
  }

  testWidgets('처음 실행하면 학교급을 고르고, 고른 값이 저장되어 그 학교급 3칸이 보인다', (tester) async {
    store = _FakeLevelStore();
    await pumpHome(tester);

    expect(find.byType(LevelPickerScreen), findsOneWidget);
    expect(find.byType(CellTile), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pick-middle')));
    await tester.pumpAndSettle();

    expect(store.saved, SchoolLevel.middle);
    expect(find.text('영단어 · 중등'), findsOneWidget);
    expect(find.byType(CellTile), findsNWidgets(3));
    for (final d in Difficulty.values) {
      expect(
        find.byKey(ValueKey('cell-${Cell.of(SchoolLevel.middle, d).id}')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cell-middle_hard')),
        matching: find.text('4단어'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('저장된 학교급이 있으면 고르는 화면 없이 바로 그 칸들이 보인다', (tester) async {
    store = _FakeLevelStore(SchoolLevel.high);
    await pumpHome(tester);

    expect(find.byType(LevelPickerScreen), findsNothing);
    expect(find.text('영단어 · 고등'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cell-high_hard')),
        matching: find.text('5단어'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cell-elementary_easy')), findsNothing);
  });

  testWidgets('메뉴 아이콘을 누르면 학교급을 바꿀 수 있고 바꾼 값이 저장된다', (tester) async {
    store = _FakeLevelStore(SchoolLevel.high);
    await pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-level-elementary')));
    await tester.pumpAndSettle();

    expect(store.saved, SchoolLevel.elementary);
    expect(find.text('영단어 · 초등'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cell-elementary_easy')),
        matching: find.text('2단어'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('메뉴에서 학교급을 빠르게 두 번 눌러도 첫 화면이 닫히지 않는다', (tester) async {
    store = _FakeLevelStore(SchoolLevel.high);
    await tester.pumpWidget(
      app(MaterialApp.router(routerConfig: createRouter())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    final item = find.byKey(const ValueKey('menu-level-middle'));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50)); // 메뉴가 닫히는 중
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('영단어 · 중등'), findsOneWidget);
    expect(find.byType(CellTile), findsNWidgets(3));
  });

  testWidgets('학교급 저장에 실패해도 이번 실행에서는 고른 값으로 보이고 실패를 알린다', (tester) async {
    store = _FakeLevelStore()..fail = true;
    await pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pick-elementary')));
    await tester.pumpAndSettle();

    expect(find.text('영단어 · 초등'), findsOneWidget);
    expect(find.textContaining('저장하지 못했습니다'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('칸을 누르면 카드 학습·시험을 고르고 고른 화면으로 간다', (tester) async {
    store = _FakeLevelStore(SchoolLevel.elementary);
    await tester.pumpWidget(
      app(MaterialApp.router(routerConfig: createRouter())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cell-elementary_easy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mode-study')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mode-quiz')));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cell-elementary_easy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mode-study')));
    await tester.pumpAndSettle();
    expect(find.byType(StudyScreen), findsOneWidget);
  });
}
