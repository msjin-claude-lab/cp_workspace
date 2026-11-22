import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_books.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/home/home_screen.dart';
import 'package:vocab/features/my_words/word_book_screen.dart';
import 'package:vocab/features/my_words/word_books_screen.dart';
import 'package:vocab/features/quiz/quiz.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocab/router.dart';

import '../fakes.dart';

void main() {
  late FakeRecords records;
  late FakeWordBooks books;
  late GoRouter router;

  setUp(() {
    records = FakeRecords();
    books = FakeWordBooks(records);
  });

  /// 칸 홈(초등 [난이도 : 쉬움])에서 시작한다. 내 단어장은 [books]에 있는 것.
  Future<void> pumpApp(WidgetTester tester) async {
    // ☰ 메뉴는 기본 단어장 9개 아래에 내 단어장이 온다 — 목록은 보이는 줄만 만들므로 화면을 길게 한다
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = createRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(
            FakeRepository({
              Cell.elementaryEasy: [fakeWord('ee-001', 'apple', '사과')],
            }),
          ),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(Cell.elementaryEasy),
          ),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          studyRecordsProvider.overrideWithValue(records),
          wordBooksProvider.overrideWithValue(books),
          quizRandomProvider.overrideWithValue(Random(5)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 단어장 하나를 칸 홈 위에 연다(☰ 메뉴 → 내 단어장 → 단어장과 같은 쌓임).
  Future<void> openBook(WidgetTester tester, int id) async {
    await pumpApp(tester);
    router.push('/books');
    await tester.pumpAndSettle();
    router.push('/books/$id');
    await tester.pumpAndSettle();
  }

  /// 화면 밖에 있을 수 있는 것을 보이게 옮긴 뒤 누른다(시험용 화면 800×600).
  Future<void> tapShown(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) =>
      tapShown(tester, find.byKey(ValueKey(key)));

  /// 지금 시험 문제에 맞게(또는 틀리게) 답한다. 문제 글자로 정답 보기를 찾는다.
  Future<void> answer(
    WidgetTester tester,
    List<Word> words, {
    required bool correct,
  }) async {
    final prompt = tester
        .widget<Text>(find.byKey(const ValueKey('quiz-prompt')))
        .data!;
    final word = words.firstWhere(
      (w) => w.word == prompt || w.meaning == prompt,
    );
    final right = prompt == word.word ? word.meaning : word.word;
    for (var i = 0; i < quizOptionCount; i++) {
      final option = find.byKey(ValueKey('quiz-option-$i'));
      final label = tester
          .widget<Text>(
            find.descendant(of: option, matching: find.byType(Text)),
          )
          .data;
      if ((label == right) == correct) {
        await tapShown(tester, option);
        return;
      }
    }
    fail('고를 보기를 찾지 못했다');
  }

  // 내 단어장(직접 단어를 넣는 기능)은 2026-11-22부터 화면에 들어가는 길이 없다 —
  // 사용자가 메뉴에서 빼라고 했고, 어디에 둘지는 아직 정하지 않았다. 기능은 남아 있어 주소로 열어 시험한다.
  testWidgets('단어장 목록(/books)에서 지우고, 이름을 넣어 단어장을 만든다', (tester) async {
    books.seed('있던 것', const []);
    await pumpApp(tester);

    router.push('/books');
    await tester.pumpAndSettle();

    expect(find.byType(WordBooksScreen), findsOneWidget);
    await tapKey(tester, 'book-menu-1');
    await tapKey(tester, 'book-delete');
    await tapKey(tester, 'confirm-delete');
    expect(find.byKey(const ValueKey('books-empty')), findsOneWidget);

    // 빈 이름은 받지 않는다
    await tapKey(tester, 'books-add');
    await tapKey(tester, 'book-name-save');
    expect(find.text('이름을 입력하세요'), findsOneWidget);
    expect(books.names, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('book-name-field')),
      '  여행 영어  ',
    );
    await tapKey(tester, 'book-name-save');
    expect(books.names.values, ['여행 영어']); // 앞뒤 공백은 뗀다
    expect(find.text('여행 영어'), findsOneWidget);
    expect(find.text('0단어'), findsOneWidget);

    await tapShown(tester, find.text('여행 영어'));
    expect(find.byType(WordBookScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, '여행 영어'), findsOneWidget);

    // ← 뒤로 두 번이면 칸 홈
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CellHomeScreen), findsOneWidget);
  });

  testWidgets('목록에서 단어장 이름을 바꾸고, 물어본 뒤 지운다', (tester) async {
    final keep = books.seed('남길 것', [('cat', '고양이')]);
    final drop = books.seed('지울 것', [('sun', '해'), ('moon', '달')]);
    await pumpApp(tester);
    router.push('/books');
    await tester.pumpAndSettle();
    expect(find.text('1단어'), findsOneWidget);
    expect(find.text('2단어'), findsOneWidget);

    await tapKey(tester, 'book-menu-$keep');
    await tapShown(tester, find.text('이름 바꾸기'));
    await tester.enterText(find.byKey(const ValueKey('book-name-field')), '동물');
    await tapKey(tester, 'book-name-save');
    expect(books.names[keep], '동물');
    expect(find.text('동물'), findsOneWidget);

    await tapKey(tester, 'book-menu-$drop');
    await tapShown(tester, find.text('지우기'));
    expect(find.text('지울 것 단어장을 지울까요?'), findsOneWidget);
    await tapShown(tester, find.text('취소'));
    expect(books.names.containsKey(drop), isTrue); // 취소하면 그대로

    await tapKey(tester, 'book-menu-$drop');
    await tapShown(tester, find.text('지우기'));
    await tapKey(tester, 'confirm-delete');
    expect(books.names.containsKey(drop), isFalse);
    expect(find.text('지울 것'), findsNothing);
    expect(find.text('동물'), findsOneWidget);
  });

  testWidgets('단어 추가는 영단어·뜻이 비면 막고, 예문·해석은 없어도 된다. 고치고 지울 수 있다', (
    tester,
  ) async {
    final id = books.seed('내 것', const []);
    await openBook(tester, id);

    expect(find.byKey(const ValueKey('book-empty')), findsOneWidget);
    expect(find.text('0단어'), findsOneWidget);
    // 단어가 없으면 카드 학습도 막힌다
    final study = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('book-study')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(study.onPressed, isNull);

    await tapKey(tester, 'book-add-word');
    await tapKey(tester, 'word-save');
    expect(find.text('영단어를 입력하세요'), findsOneWidget);
    expect(find.text('뜻을 입력하세요'), findsOneWidget);

    // 공백만 넣은 것도 비어 있는 것으로 본다
    await tester.enterText(
      find.byKey(const ValueKey('word-field-word')),
      'cat',
    );
    await tester.enterText(
      find.byKey(const ValueKey('word-field-meaning')),
      '  ',
    );
    await tapKey(tester, 'word-save');
    expect(find.text('영단어를 입력하세요'), findsNothing);
    expect(find.text('뜻을 입력하세요'), findsOneWidget);
    expect(books.bookWords[id], isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('word-field-meaning')),
      ' 고양이 ',
    );
    await tapKey(tester, 'word-save');

    final added = books.bookWords[id]!.single;
    expect(
      (added.word, added.meaning, added.example, added.exampleMeaning),
      ('cat', '고양이', '', ''),
    );
    expect(find.text('1단어'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);

    // 누르면 고치기 — 지금 내용이 채워져 있다
    await tapShown(tester, find.text('cat'));
    expect(find.text('단어 고치기'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('word-field-meaning')),
      '고양이(동물)',
    );
    await tester.enterText(
      find.byKey(const ValueKey('word-field-example')),
      'A cat sleeps.',
    );
    await tapKey(tester, 'word-save');
    final edited = books.bookWords[id]!.single;
    expect(
      (edited.id, edited.word, edited.meaning, edited.example),
      (added.id, 'cat', '고양이(동물)', 'A cat sleeps.'),
    );
    expect(find.text('고양이(동물)'), findsOneWidget);

    await tapKey(tester, 'book-word-delete-${added.id}');
    await tapKey(tester, 'confirm-delete');
    expect(books.bookWords[id], isEmpty);
    expect(find.byKey(const ValueKey('book-empty')), findsOneWidget);
  });

  testWidgets('뜻이 같은 단어 때문에 보기 4개를 만들 수 없으면 시험이 막히고 까닭을 알려 준다', (tester) async {
    final id = books.seed('내 것', [
      ('big', '큰'),
      ('large', '큰'),
      ('cat', '고양이'),
      ('dog', '개'),
    ]);
    await openBook(tester, id);

    expect(
      find.text('영단어와 뜻이 서로 다른 단어가 4개 이상 있어야 시험을 볼 수 있습니다'),
      findsOneWidget,
    );
    await tapKey(tester, 'book-quiz');
    expect(find.byType(QuizScreen), findsNothing);
  });

  testWidgets('단어가 4개보다 적은 단어장의 오답 노트는 오답 시험이 막히고 까닭을 알려 준다(지우기는 된다)', (
    tester,
  ) async {
    final id = books.seed('내 것', [('cat', '고양이'), ('dog', '개'), ('sun', '해')]);
    final deck = BookDeck(bookId: id, name: '내 것');
    records.notes.add(fakeNote(books.bookWords[id]!.first.id, deck));
    await openBook(tester, id);

    await tapKey(tester, 'book-wrong');
    expect(find.byKey(const ValueKey('wrong-quiz-locked')), findsOneWidget);
    expect(find.text('단어가 4개 이상 있어야 시험을 볼 수 있습니다'), findsOneWidget);
    await tapKey(tester, 'wrong-quiz');
    expect(find.byType(QuizScreen), findsNothing);
    expect(find.byKey(const ValueKey('wrong-study')), findsOneWidget);
  });

  testWidgets('시험은 단어가 4개보다 적으면 막혀 있고, 4개가 되면 열린다', (tester) async {
    final id = books.seed('내 것', [('cat', '고양이'), ('dog', '개'), ('sun', '해')]);
    await openBook(tester, id);

    FilledButton quizButton() => tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('book-quiz')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(quizButton().onPressed, isNull);
    expect(find.text('단어가 4개 이상 있어야 시험을 볼 수 있습니다'), findsOneWidget);

    await tapKey(tester, 'book-add-word');
    await tester.enterText(
      find.byKey(const ValueKey('word-field-word')),
      'moon',
    );
    await tester.enterText(
      find.byKey(const ValueKey('word-field-meaning')),
      '달',
    );
    await tapKey(tester, 'word-save');

    expect(find.text('4단어'), findsOneWidget);
    expect(quizButton().onPressed, isNotNull);
    expect(find.byKey(const ValueKey('book-quiz-locked')), findsNothing);

    await tapKey(tester, 'book-quiz');
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('내 것 - 시험'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('카드 학습은 단어장 단어를 넣은 순서대로 보여 주고, 빈 예문 줄은 그리지 않는다', (tester) async {
    final id = books.seed('내 것', [('cat', '고양이'), ('dog', '개')]);
    await openBook(tester, id);

    await tapKey(tester, 'book-study');
    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('내 것 - 카드 학습'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);

    await tapKey(tester, 'study-card');
    expect(find.text('고양이'), findsOneWidget);
    expect(find.text(''), findsNothing); // 예문·해석이 없으면 빈 글자를 두지 않는다
    await tapKey(tester, 'study-unknown');
    expect(find.text('dog'), findsOneWidget);

    final cat = books.bookWords[id]!.first;
    expect(records.studied, [(cat.id, false)]);
    expect(records.notes.single.deck, BookDeck(bookId: id, name: '내 것'));

    // 돌아오면 단어장 화면의 오답 수가 바뀐다
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });

  testWidgets('시험에서 틀린 단어는 그 단어장의 오답 노트에 들어가고, 오답 시험에서 맞히면 빠진다', (
    tester,
  ) async {
    final id = books.seed('내 것', [
      ('cat', '고양이'),
      ('dog', '개'),
      ('sun', '해'),
      ('moon', '달'),
    ]);
    // 다른 칸의 오답은 이 단어장 노트에 보이지 않는다
    records.notes.add(fakeNote('ee-001', Cell.elementaryEasy));
    final words = books.bookWords[id]!;
    await openBook(tester, id);
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);

    await tapKey(tester, 'book-quiz');
    await answer(tester, words, correct: false);
    for (var i = 1; i < 4; i++) {
      await tapKey(tester, 'quiz-next');
      await answer(tester, words, correct: true);
    }
    await tapKey(tester, 'quiz-next');
    expect(find.text('4문제 중 3문제 맞혔습니다'), findsOneWidget);
    final missed = records.quizzed.firstWhere((q) => !q.$2).$1;

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);

    await tapKey(tester, 'book-wrong');
    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(find.text('내 것 - 오답 노트'), findsOneWidget);
    expect(find.byKey(ValueKey('wrong-$missed')), findsOneWidget);
    expect(find.text('apple'), findsNothing);

    await tapKey(tester, 'wrong-quiz');
    expect(find.text('내 것 - 오답 시험'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    await answer(tester, words, correct: true);
    await tapKey(tester, 'quiz-next');
    await tapShown(tester, find.text('오답 노트로'));

    expect(records.removed, [missed]);
    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
    // 다른 칸의 오답은 그대로
    expect(records.notes.map((n) => n.wordId), ['ee-001']);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 0단어'), findsOneWidget);
  });

  testWidgets('오답 다시 보기의 제목도 단어장 이름을 쓴다', (tester) async {
    final id = books.seed('내 것', [('cat', '고양이'), ('dog', '개')]);
    final dog = books.bookWords[id]![1];
    records.notes.add(fakeNote(dog.id, BookDeck(bookId: id, name: '내 것')));
    await openBook(tester, id);

    await tapKey(tester, 'book-wrong');
    await tapKey(tester, 'wrong-study');
    expect(find.text('내 것 - 오답 다시 보기'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('dog'), findsOneWidget);
  });

  testWidgets('없는 단어장 주소는 안내만 보인다', (tester) async {
    await pumpApp(tester);
    router.push('/study/book_99');
    await tester.pumpAndSettle();
    expect(find.text('없는 단어장입니다'), findsOneWidget);
  });
}
