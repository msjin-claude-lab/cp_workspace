import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';

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
              exampleMeaning: 'em$i'),
      ];
}

void main() {
  testWidgets('첫 화면에 학교급 3줄 × 난이도 3칸과 칸별 단어 수가 보인다',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        wordRepositoryProvider.overrideWithValue(
            _FakeRepository({Cell.elementaryEasy: 2, Cell.highHard: 5})),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    for (final level in SchoolLevel.values) {
      expect(find.text(level.label), findsOneWidget);
    }
    expect(find.byType(CellTile), findsNWidgets(9));
    for (final cell in Cell.values) {
      expect(find.byKey(ValueKey('cell-${cell.id}')), findsOneWidget);
    }
    expect(
      find.descendant(
          of: find.byKey(const ValueKey('cell-elementary_easy')),
          matching: find.text('2단어')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: find.byKey(const ValueKey('cell-high_hard')),
          matching: find.text('5단어')),
      findsOneWidget,
    );
    expect(find.text('0단어'), findsNWidgets(7));
  });
}
