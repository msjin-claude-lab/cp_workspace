import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocara/data/app_settings.dart';
import 'package:vocara/data/cell.dart';
import 'package:vocara/data/counts.dart';
import 'package:vocara/data/study_decks.dart';

import '../fakes.dart';

/// 설정은 단어장마다 따로(2026-11-22 사용자 결정 — "설정은 그 단어장의 고유 설정이다").
/// 값: 단어장 고유 값 → 옛 공통 설정(7판 전, 읽기만) → 기본값(카드 50, 시험 20) 순으로 쓸 수 있는 첫 값.
void main() {
  late FakeStudyDecks decks;

  setUp(() => decks = FakeStudyDecks());

  ProviderContainer containerOf(FakeLegacySettingsStore legacy) {
    final container = ProviderContainer(
      overrides: [
        legacySettingsStoreProvider.overrideWithValue(legacy),
        studyDecksProvider.overrideWithValue(decks),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// 앱을 새로 연 것처럼 새 컨테이너에서 읽는다.
  Future<DeckSettings> read(FakeLegacySettingsStore legacy, Deck deck) =>
      containerOf(legacy).read(deckSettingsProvider(deck).future);

  group('7판 전에 있던 단어장(설정 열이 NULL)', () {
    test('옛 공통 설정값이 30이면 30을 쓴다', () async {
      final old = decks.seed('옛것', Cell.elementaryEasy);
      expect(
        await read(FakeLegacySettingsStore(cardCount: 30, quizCount: 30), old),
        const DeckSettings(cardCount: 30, quizCount: 30),
      );
    });

    test('옛 공통 설정값도 없으면 카드 50, 시험 20 기본값이다', () async {
      final old = decks.seed('옛것', Cell.elementaryEasy);
      final s = await read(FakeLegacySettingsStore(), old);
      expect(s.cardCount, 50);
      expect(s.quizCount, 20);
    });

    test('옛 공통 설정값이 범위 밖(0·음수·1000 이상)이면 기본값이다', () async {
      final old = decks.seed('옛것', Cell.elementaryEasy);
      for (final bad in [0, -1, 1000, 5000]) {
        final s = await read(
          FakeLegacySettingsStore(cardCount: bad, quizCount: bad),
          old,
        );
        expect(s.cardCount, 50, reason: '$bad');
        expect(s.quizCount, 20, reason: '$bad');
      }
    });

    test('옛 공통 설정값이 1~999면 목록 밖이어도 그대로 쓴다', () async {
      final old = decks.seed('옛것', Cell.elementaryEasy);
      for (final n in [1, 7, 45, 999]) {
        expect(
          await read(FakeLegacySettingsStore(cardCount: n, quizCount: n), old),
          DeckSettings(cardCount: n, quizCount: n),
        );
      }
    });

    test('단어 수만 고유로 바꾸면 그 값은 저장되고 문항 수는 계속 옛 값을 물려받는다', () async {
      final old = decks.seed('옛것', Cell.elementaryEasy);
      final legacy = FakeLegacySettingsStore(cardCount: 30, quizCount: 30);
      final container = containerOf(legacy);
      await container.read(deckSettingsProvider(old).future);
      expect(
        await container
            .read(deckSettingsProvider(old).notifier)
            .setCardCount(10),
        isTrue,
      );
      expect(decks.cardCounts[old.deckId], 10);
      expect(decks.quizCounts[old.deckId], isNull);
      // 옛 공통 설정은 읽기만 한다
      expect(legacy.cardCount, 30);

      expect(
        await read(legacy, old),
        const DeckSettings(cardCount: 10, quizCount: 30),
      );
      // 단어 수는 고유 값이 생겨 옛 값을 보지 않고, 문항 수는 여전히 옛 값을 따른다
      legacy
        ..cardCount = 99
        ..quizCount = 40;
      expect(
        await read(legacy, old),
        const DeckSettings(cardCount: 10, quizCount: 40),
      );
    });
  });

  test('고유 값이 있으면 옛 공통 설정값은 무시한다', () async {
    final deck = decks.seed(
      '새것',
      Cell.elementaryEasy,
      cardCount: 12,
      quizCount: 8,
    );
    expect(
      await read(FakeLegacySettingsStore(cardCount: 30, quizCount: 30), deck),
      const DeckSettings(cardCount: 12, quizCount: 8),
    );
  });

  test('새로 만든 단어장은 옛 공통 설정을 물려받지 않고 기본값을 쓴다', () async {
    final deck = await decks.createDeck('새것', Cell.elementaryEasy);
    expect(
      await read(FakeLegacySettingsStore(cardCount: 30, quizCount: 30), deck),
      const DeckSettings(cardCount: 50, quizCount: 20),
    );
  });

  test('DB에 저장된 값이 범위 밖이면 옛 공통 값, 그것도 없으면 기본값을 쓴다', () async {
    final deck = decks.seed(
      '깨진 것',
      Cell.elementaryEasy,
      cardCount: 0,
      quizCount: 1000,
    );
    expect(
      await read(FakeLegacySettingsStore(cardCount: 30), deck),
      const DeckSettings(cardCount: 30, quizCount: 20),
    );
  });

  test('한 단어장의 값을 바꿔도 다른 단어장 값은 그대로다', () async {
    final a = decks.seed(
      'A',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    final b = decks.seed(
      'B',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    final container = containerOf(FakeLegacySettingsStore());
    await container.read(deckSettingsProvider(a).future);
    await container.read(deckSettingsProvider(b).future);
    final notifier = container.read(deckSettingsProvider(a).notifier);
    expect(await notifier.setCardCount(10), isTrue);
    expect(await notifier.setQuizCount(30), isTrue);

    expect(
      container.read(deckSettingsProvider(a)).value,
      const DeckSettings(cardCount: 10, quizCount: 30),
    );
    expect(
      container.read(deckSettingsProvider(b)).value,
      const DeckSettings(cardCount: 50, quizCount: 20),
    );
    expect(decks.cardCounts, {a.deckId: 10, b.deckId: 50});
    expect(decks.quizCounts, {a.deckId: 30, b.deckId: 20});
    // 다시 열어도 같다
    expect(
      await read(FakeLegacySettingsStore(), a),
      const DeckSettings(cardCount: 10, quizCount: 30),
    );
    expect(
      await read(FakeLegacySettingsStore(), b),
      const DeckSettings(cardCount: 50, quizCount: 20),
    );
  });

  test('직접 입력한 값(1~999)도 그 단어장에 남고 다시 열어도 같다', () async {
    final deck = decks.seed(
      'A',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    final container = containerOf(FakeLegacySettingsStore());
    final notifier = container.read(deckSettingsProvider(deck).notifier);
    await container.read(deckSettingsProvider(deck).future);
    expect(await notifier.setCardCount(45), isTrue);
    expect(await notifier.setQuizCount(7), isTrue);
    expect(
      await read(FakeLegacySettingsStore(), deck),
      const DeckSettings(cardCount: 45, quizCount: 7),
    );
  });

  test('읽기가 실패한 화면을 닫았다 다시 열면 다시 읽어 고유 값을 쓴다', () async {
    final deck = decks.seed(
      'A',
      Cell.elementaryEasy,
      cardCount: 12,
      quizCount: 8,
    );
    final container = containerOf(FakeLegacySettingsStore(cardCount: 30));
    decks.failLoad = true;
    var sub = container.listen(deckSettingsProvider(deck), (_, _) {});
    // 읽지 못해도 막지 않고 옛 공통값·기본값으로 연다
    expect(
      await container.read(deckSettingsProvider(deck).future),
      const DeckSettings(cardCount: 30, quizCount: 20),
    );
    // 화면을 닫는다 — 듣는 곳이 없어지면 provider가 버려진다
    sub.close();
    await Future<void>.delayed(Duration.zero);

    decks.failLoad = false;
    sub = container.listen(deckSettingsProvider(deck), (_, _) {});
    expect(
      await container.read(deckSettingsProvider(deck).future),
      const DeckSettings(cardCount: 12, quizCount: 8),
    );
    sub.close();
  });

  test('두 값을 기다리지 않고 잇달아 바꿔도 서로 덮어쓰지 않는다', () async {
    final deck = decks.seed(
      'A',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    final container = containerOf(FakeLegacySettingsStore());
    container.listen(deckSettingsProvider(deck), (_, _) {});
    await container.read(deckSettingsProvider(deck).future);
    final notifier = container.read(deckSettingsProvider(deck).notifier);
    await Future.wait([notifier.setCardCount(10), notifier.setQuizCount(5)]);

    expect(
      container.read(deckSettingsProvider(deck)).value,
      const DeckSettings(cardCount: 10, quizCount: 5),
    );
    expect(decks.cardCounts[deck.deckId], 10);
    expect(decks.quizCounts[deck.deckId], 5);
  });

  test('저장하지 못해도 이번 실행에서는 고른 값을 쓰고 false를 돌려준다', () async {
    final deck = decks.seed(
      'A',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    decks.failSave = true;
    final container = containerOf(FakeLegacySettingsStore());
    final notifier = container.read(deckSettingsProvider(deck).notifier);
    await container.read(deckSettingsProvider(deck).future);
    expect(await notifier.setCardCount(30), isFalse);
    expect(container.read(deckSettingsProvider(deck)).value?.cardCount, 30);
    expect(decks.cardCounts[deck.deckId], 50);
  });

  group('내장 칸(Cell)을 직접 열 때는 고유 설정이 없다', () {
    test('옛 공통 설정값을, 없으면 기본값을 읽는다', () async {
      expect(
        await read(
          FakeLegacySettingsStore(cardCount: 30, quizCount: 7),
          Cell.elementaryEasy,
        ),
        const DeckSettings(cardCount: 30, quizCount: 7),
      );
      expect(
        await read(FakeLegacySettingsStore(), Cell.elementaryEasy),
        const DeckSettings(cardCount: 50, quizCount: 20),
      );
    });

    test('값을 바꿀 수 없다(읽기만)', () async {
      final legacy = FakeLegacySettingsStore(cardCount: 30);
      final container = containerOf(legacy);
      await container.read(deckSettingsProvider(Cell.elementaryEasy).future);
      final notifier = container.read(
        deckSettingsProvider(Cell.elementaryEasy).notifier,
      );
      await expectLater(notifier.setCardCount(10), throwsUnsupportedError);
      expect(
        container.read(deckSettingsProvider(Cell.elementaryEasy)).value,
        const DeckSettings(cardCount: 30, quizCount: 20),
      );
      expect(legacy.cardCount, 30);
      expect(decks.cardCounts, isEmpty);
    });
  });

  test('isValidCount는 1~999만 받는다', () {
    expect(isValidCount(null), isFalse);
    expect(isValidCount(0), isFalse);
    expect(isValidCount(1), isTrue);
    expect(isValidCount(999), isTrue);
    expect(isValidCount(1000), isFalse);
    // 카드 학습 "전체"(9999)는 카드에만 쓸 수 있다(2026-11-24)
    expect(isValidCount(allCardsCount), isFalse);
    expect(isValidCardCount(allCardsCount), isTrue);
    expect(isValidCardCount(999), isTrue);
    expect(isValidCardCount(1000), isFalse);
    expect(isValidCardCount(null), isFalse);
  });
}
