import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/progress/progress_calendar.dart';
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

  testWidgets('진도는 지금 난이도의 외운 수/전체·오답 수만 보여 주고, 날짜별 기록과 진행 일차를 보여 준다', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = dayKey(now);
    // 사흘 전에 시작하고 그 사이 이틀은 쉬었다 → 진행 4일차
    final firstDay = dayKey(DateTime(now.year, now.month, now.day - 3));
    records.progressValue = Progress(
      memorized: {Cell.elementaryEasy: 3, Cell.middleHard: 9}, // 9는 전체(2)를 넘음
      wrong: {Cell.elementaryEasy: 1},
      days: [
        DayStat(day: today, studied: 12, correct: 5),
        DayStat(day: firstDay, studied: 4, correct: 0),
      ],
    );
    await openProgress(tester);

    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.text('초등 [난이도 : 쉬움] - 진도'), findsOneWidget);
    expect(find.text('진행 4일차'), findsOneWidget);
    // 지금 난이도(초등 쉬움) 것만 — 다른 난이도(중등 어려움 2/2)는 보이지 않는다
    expect(find.text('외움 3/5 · 오답 1'), findsOneWidget);
    expect(find.textContaining('외움'), findsOneWidget);

    // 날짜별 기록은 달력 — 처음에는 오늘이 골라져 있다
    expect(find.byType(ProgressCalendar), findsOneWidget);
    expect(
      find.text('${now.month}월 ${now.day}일 · 공부 12 · 시험 맞힘 5'),
      findsOneWidget,
    );
  });

  testWidgets('달력: 공부한 날을 누르면 그날 기록이, 안 한 날은 기록 없음이 보이고 달을 넘길 수 있다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressCalendar(
            today: DateTime(2026, 11, 22),
            days: const [
              DayStat(day: '2026-11-20', studied: 18, correct: 9),
              DayStat(day: '2026-10-31', studied: 3, correct: 1),
            ],
          ),
        ),
      ),
    );

    expect(find.text('2026년 11월'), findsOneWidget);
    // 2026-11-01은 일요일 — 첫 줄 첫 칸
    final first = tester.getTopLeft(
      find.byKey(const ValueKey('cal-2026-11-01')),
    );
    final sunday = tester.getTopLeft(find.text('일'));
    expect((first.dx - sunday.dx).abs(), lessThan(60));
    expect(find.byKey(const ValueKey('cal-2026-11-30')), findsOneWidget);
    expect(find.byKey(const ValueKey('cal-2026-11-31')), findsNothing);
    // 오늘(22일)은 기록이 없다
    expect(find.text('11월 22일 · 공부한 기록이 없습니다'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cal-2026-11-20')));
    await tester.pump();
    expect(find.text('11월 20일 · 공부 18 · 시험 맞힘 9'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cal-prev')));
    await tester.pump();
    expect(find.text('2026년 10월'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cal-2026-10-31')));
    await tester.pump();
    expect(find.text('10월 31일 · 공부 3 · 시험 맞힘 1'), findsOneWidget);

    // 12월에서 다음 달로 넘기면 해가 바뀐다
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('cal-next')));
      await tester.pump();
    }
    expect(find.text('2027년 1월'), findsOneWidget);
  });

  testWidgets('기록이 없으면 아직 시작하지 않았다고 알린다', (tester) async {
    await openProgress(tester);

    expect(find.text('아직 시작하지 않았습니다'), findsOneWidget);
    expect(find.text('외움 0/5 · 오답 0'), findsOneWidget);
    expect(find.textContaining('공부한 기록이 없습니다'), findsOneWidget);
  });
}
