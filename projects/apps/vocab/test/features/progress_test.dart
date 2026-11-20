import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/progress/progress_screen.dart';
import 'package:vocab/router.dart';

import '../fakes.dart';

void main() {
  late FakeRecords records;

  final words = {
    Cell.elementaryEasy: [
      for (var i = 0; i < 5; i++) fakeWord('ee-00$i', 'e$i', '뜻$i'),
    ],
    Cell.middleHard: [
      for (var i = 0; i < 2; i++) fakeWord('mh-00$i', 'm$i', '중$i'),
    ],
  };

  setUp(() => records = FakeRecords());

  /// 홈(초등 쉬움)에서 진도 버튼으로 들어간다.
  Future<void> openProgress(WidgetTester tester) async {
    // 목록은 보이는 줄만 만든다 — 9줄과 날짜가 한 번에 보이도록 시험용 화면을 길게 한다
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(Cell.elementaryEasy),
          ),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          studyRecordsProvider.overrideWithValue(records),
        ],
        child: MaterialApp.router(routerConfig: createRouter()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-progress')));
    await tester.pumpAndSettle();
  }

  Finder inRow(Cell cell, String text) => find.descendant(
    of: find.byKey(ValueKey('progress-${cell.id}')),
    matching: find.text(text),
  );

  testWidgets('진도는 9개 난이도마다 외운 수/전체와 오답 수를 보여 주고, 날짜별 기록과 연속 학습일을 보여 준다', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = dayKey(now);
    final yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
    records.progressValue = Progress(
      memorized: {Cell.elementaryEasy: 3, Cell.middleHard: 9}, // 9는 전체(2)를 넘음
      wrong: {Cell.elementaryEasy: 1},
      days: [
        DayStat(day: today, studied: 12, correct: 5),
        DayStat(day: yesterday, studied: 4, correct: 0),
      ],
    );
    await openProgress(tester);

    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.text('연속 학습 2일'), findsOneWidget);
    for (final cell in Cell.values) {
      expect(find.byKey(ValueKey('progress-${cell.id}')), findsOneWidget);
    }
    expect(inRow(Cell.elementaryEasy, '외움 3/5 · 오답 1'), findsOneWidget);
    expect(inRow(Cell.middleHard, '외움 2/2 · 오답 0'), findsOneWidget);
    expect(inRow(Cell.highEasy, '외움 0/0 · 오답 0'), findsOneWidget);

    final dayTile = find.byKey(ValueKey('progress-day-$today'));
    await tester.scrollUntilVisible(dayTile, 200);
    expect(
      find.descendant(of: dayTile, matching: find.text('공부 12 · 시험 맞힘 5')),
      findsOneWidget,
    );
  });

  testWidgets('기록이 없으면 연속 학습 0일과 안내를 보여 준다', (tester) async {
    await openProgress(tester);

    expect(find.text('연속 학습 0일'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('아직 공부한 기록이 없습니다'), 200);
    expect(find.text('아직 공부한 기록이 없습니다'), findsOneWidget);
  });
}
