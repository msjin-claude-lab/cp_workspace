import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/data/app_settings.dart';

import '../fakes.dart';

void main() {
  ProviderContainer containerOf(FakeAppSettingsStore store) {
    final container = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('저장된 것이 없으면 카드 50, 시험 20이 기본이다', () async {
    final s = await containerOf(FakeAppSettingsStore())
        .read(appSettingsProvider.future);
    expect(s.cardCount, 50);
    expect(s.quizCount, 20);
  });

  test('저장된 값을 읽는다', () async {
    final s = await containerOf(
      FakeAppSettingsStore(cardCount: 10, quizCount: 30),
    ).read(appSettingsProvider.future);
    expect(s.cardCount, 10);
    expect(s.quizCount, 30);
  });

  test('쓸 수 없는 값(0·음수·1000 이상)은 기본값으로 본다', () async {
    for (final bad in [0, -1, 1000, 5000]) {
      final s = await containerOf(
        FakeAppSettingsStore(cardCount: bad, quizCount: bad),
      ).read(appSettingsProvider.future);
      expect(s.cardCount, 50, reason: '$bad');
      expect(s.quizCount, 20, reason: '$bad');
    }
  });

  test('직접 입력한 값(1~999)은 목록 밖이어도 그대로 읽는다', () async {
    for (final n in [1, 7, 45, 999]) {
      final s = await containerOf(
        FakeAppSettingsStore(cardCount: n, quizCount: n),
      ).read(appSettingsProvider.future);
      expect(s, AppSettings(cardCount: n, quizCount: n));
    }
  });

  test('직접 입력한 값도 저장소에 남고 다시 열어도 같다', () async {
    final store = FakeAppSettingsStore();
    final container = containerOf(store);
    final notifier = container.read(appSettingsProvider.notifier);
    await container.read(appSettingsProvider.future);
    expect(await notifier.setCardCount(45), isTrue);
    expect(await notifier.setQuizCount(7), isTrue);
    final again = await containerOf(store).read(appSettingsProvider.future);
    expect(again, const AppSettings(cardCount: 45, quizCount: 7));
  });

  test('isValidCount는 1~999만 받는다', () {
    expect(isValidCount(null), isFalse);
    expect(isValidCount(0), isFalse);
    expect(isValidCount(1), isTrue);
    expect(isValidCount(999), isTrue);
    expect(isValidCount(1000), isFalse);
  });

  test('값을 바꾸면 저장소에 남고 다시 열어도 같다', () async {
    final store = FakeAppSettingsStore();
    final container = containerOf(store);
    final notifier = container.read(appSettingsProvider.notifier);
    await container.read(appSettingsProvider.future);
    expect(await notifier.setCardCount(20), isTrue);
    expect(await notifier.setQuizCount(10), isTrue);
    expect(store.cardCount, 20);
    expect(store.quizCount, 10);
    final again = await containerOf(store).read(appSettingsProvider.future);
    expect(again, const AppSettings(cardCount: 20, quizCount: 10));
  });

  test('저장하지 못해도 이번 실행에서는 고른 값을 쓰고 false를 돌려준다', () async {
    final store = FakeAppSettingsStore()..fail = true;
    final container = containerOf(store);
    final notifier = container.read(appSettingsProvider.notifier);
    await container.read(appSettingsProvider.future);
    expect(await notifier.setCardCount(30), isFalse);
    expect(container.read(appSettingsProvider).value?.cardCount, 30);
    expect(store.cardCount, isNull);
  });
}
