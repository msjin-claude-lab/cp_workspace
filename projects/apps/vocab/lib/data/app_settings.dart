import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/quiz/quiz.dart' show quizLength;

/// 카드 학습 한 회차의 기본 단어 수(2026-11-22 사용자 결정).
const int defaultCardCount = 50;

/// 설정 화면에서 바로 고르는 수(카드 학습·시험 공통). 이 밖의 수는 "직접 입력"으로 넣는다.
const List<int> countChoices = [10, 20, 30, 50];

/// 직접 입력으로 넣을 수 있는 범위(2026-11-22 사용자 결정 — "단어 수랑 문항 수에 직접 입력 항목도 추가").
const int minCount = 1;
const int maxCount = 999;

/// 카드·시험 수로 쓸 수 있는 값인가. 저장된 값이 이 밖이면 기본값으로 본다.
bool isValidCount(int? n) => n != null && n >= minCount && n <= maxCount;

/// 앱 설정: 카드 학습 단어 수와 시험 문항 수. 모든 단어장에 똑같이 적용된다
/// (2026-11-22 사용자 결정 — "카드 학습 단어 개수랑 시험 문항 수 설정 가능하게").
class AppSettings {
  const AppSettings({
    this.cardCount = defaultCardCount,
    this.quizCount = quizLength,
  });

  final int cardCount;
  final int quizCount;

  AppSettings copyWith({int? cardCount, int? quizCount}) => AppSettings(
    cardCount: cardCount ?? this.cardCount,
    quizCount: quizCount ?? this.quizCount,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.cardCount == cardCount &&
      other.quizCount == quizCount;

  @override
  int get hashCode => Object.hash(cardCount, quizCount);
}

/// 설정을 기기에 남긴다. 시험에서는 가짜로 바꾼다.
/// 값이 없으면 null을 돌려주고(범위 밖 값 처리는 [isValidCount]), 기본값으로 바꾸는 것은 [AppSettingsNotifier]가 한다.
abstract interface class AppSettingsStore {
  Future<int?> loadCardCount();

  Future<int?> loadQuizCount();

  Future<void> saveCardCount(int count);

  Future<void> saveQuizCount(int count);
}

/// shared_preferences 구현(`cell_store.dart`와 같은 방식).
class PrefsAppSettingsStore implements AppSettingsStore {
  static const _cardCountKey = 'card_count';
  static const _quizCountKey = 'quiz_count';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<int?> loadCardCount() => _prefs.getInt(_cardCountKey);

  @override
  Future<int?> loadQuizCount() => _prefs.getInt(_quizCountKey);

  @override
  Future<void> saveCardCount(int count) => _prefs.setInt(_cardCountKey, count);

  @override
  Future<void> saveQuizCount(int count) => _prefs.setInt(_quizCountKey, count);
}

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => PrefsAppSettingsStore(),
);

/// 설정값. 카드·시험은 이 값을 읽은 뒤에야 회차를 만든다(읽는 동안 엉뚱한 개수가 번쩍이지 않게).
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final store = ref.read(appSettingsStoreProvider);
    // 읽지 못해도 기본값으로 연다 — 설정 때문에 학습·시험이 막히면 안 된다
    return AppSettings(
      cardCount: await _load(store.loadCardCount, defaultCardCount),
      quizCount: await _load(store.loadQuizCount, quizLength),
    );
  }

  Future<int> _load(Future<int?> Function() read, int fallback) async {
    try {
      final value = await read();
      return isValidCount(value) ? value! : fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// 값을 바로 바꾸고 저장한다. 저장하지 못해도 이번 실행에서는 고른 값을 쓰며, 그때 false.
  Future<bool> setCardCount(int count) => _set(
    (s) => s.copyWith(cardCount: count),
    () => ref.read(appSettingsStoreProvider).saveCardCount(count),
  );

  Future<bool> setQuizCount(int count) => _set(
    (s) => s.copyWith(quizCount: count),
    () => ref.read(appSettingsStoreProvider).saveQuizCount(count),
  );

  Future<bool> _set(
    AppSettings Function(AppSettings) change,
    Future<void> Function() save,
  ) async {
    final current = await future;
    state = AsyncData(change(current));
    try {
      await save();
      return true;
    } catch (_) {
      return false;
    }
  }
}
