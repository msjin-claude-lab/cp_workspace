import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cell.dart';
import 'counts.dart';
import 'study_decks.dart';

/// 단어장 하나의 설정: 카드 학습 단어 수와 시험 문항 수
/// (2026-11-22 사용자 결정 — "카드 학습 단어 개수랑 시험 문항 수 설정 가능하게",
/// 같은 날 "설정은 그 단어장의 고유 설정이다"로 단어장마다 따로).
class DeckSettings {
  const DeckSettings({
    this.cardCount = defaultCardCount,
    this.quizCount = defaultQuizCount,
  });

  final int cardCount;
  final int quizCount;

  DeckSettings copyWith({int? cardCount, int? quizCount}) => DeckSettings(
    cardCount: cardCount ?? this.cardCount,
    quizCount: quizCount ?? this.quizCount,
  );

  @override
  bool operator ==(Object other) =>
      other is DeckSettings &&
      other.cardCount == cardCount &&
      other.quizCount == quizCount;

  @override
  int get hashCode => Object.hash(cardCount, quizCount);
}

/// 옛 공통 설정(7판 전 — 모든 단어장 공통이던 때). 이제 **읽기만** 한다: 7판 전에 있던 단어장(설정 열이
/// NULL)과 내장 칸을 직접 열 때 물려받는다. 시험에서는 가짜로 바꾼다.
/// 값이 없으면 null을 돌려주고(범위 밖 값 처리는 [isValidCount]·[isValidCardCount]), 값을 정하는 것은 [DeckSettingsNotifier]가 한다.
abstract interface class LegacySettingsStore {
  Future<int?> loadCardCount();

  Future<int?> loadQuizCount();
}

/// shared_preferences 구현(`cell_store.dart`와 같은 방식).
class PrefsLegacySettingsStore implements LegacySettingsStore {
  static const _cardCountKey = 'card_count';
  static const _quizCountKey = 'quiz_count';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<int?> loadCardCount() => _prefs.getInt(_cardCountKey);

  @override
  Future<int?> loadQuizCount() => _prefs.getInt(_quizCountKey);
}

final legacySettingsStoreProvider = Provider<LegacySettingsStore>(
  (ref) => PrefsLegacySettingsStore(),
);

/// 값 하나를 정한다(2026-11-22 사용자 결정): 단어장 고유 값 → 옛 공통 값 → `fallback`(기본값) 중
/// 쓸 수 있는(`valid` — 기본 [isValidCount], 카드는 [isValidCardCount]) 첫 값. 옛 값은 고유 값을 쓸 수 없을 때만
/// 읽고, 읽지 못하면 없는 것으로 본다.
Future<int> resolveCount(
  int? own,
  Future<int?> Function() legacy,
  int fallback, {
  bool Function(int?) valid = isValidCount,
}) async {
  if (valid(own)) return own!;
  try {
    final value = await legacy();
    if (valid(value)) return value!;
  } catch (_) {
    // 설정 때문에 학습·시험이 막히면 안 된다 — 기본값으로 연다
  }
  return fallback;
}

/// 단어장 하나의 설정값. 카드·시험은 이 값을 읽은 뒤에야 회차를 만든다(읽는 동안 엉뚱한 개수가 번쩍이지 않게).
/// 이름 있는 단어장은 그 단어장의 값(한 단어장을 바꿔도 다른 단어장은 그대로), 내장 칸은 옛 공통 값 → 기본값.
/// autoDispose지만, 그 단어장이 홈인 동안에는 홈(셋째 줄의 카드 수·문항 수)이 붙잡고 있어 카드·시험·설정
/// 화면이 홈과 같은 값을 나눠 쓴다 — 설정에서 바꾸면 홈에 바로 보이고, 홈 단어장을 바꾸면 버려져
/// 다음에 다시 읽는다. 내장 칸을 직접 연 화면은 닫으면 버려진다.
final deckSettingsProvider = AsyncNotifierProvider.autoDispose
    .family<DeckSettingsNotifier, DeckSettings, Deck>(DeckSettingsNotifier.new);

class DeckSettingsNotifier extends AsyncNotifier<DeckSettings> {
  DeckSettingsNotifier(this.deck);

  final Deck deck;

  @override
  Future<DeckSettings> build() async {
    final legacy = ref.watch(legacySettingsStoreProvider);
    // 내장 칸은 고유 설정이 없다(단어장이 아니다)
    DeckCounts own = (cardCount: null, quizCount: null);
    if (deck case StudyDeck(:final deckId)) {
      final decks = ref.watch(studyDecksProvider);
      try {
        own = await decks.loadCounts(deckId);
      } catch (_) {
        // 읽지 못하면 고유 값이 없는 것으로 보고 물려받는다
      }
    }
    return DeckSettings(
      cardCount: await resolveCount(
        own.cardCount,
        legacy.loadCardCount,
        defaultCardCount,
        valid: isValidCardCount,
      ),
      quizCount: await resolveCount(
        own.quizCount,
        legacy.loadQuizCount,
        defaultQuizCount,
      ),
    );
  }

  /// 값을 바로 바꾸고 그 단어장에 저장한다. 저장하지 못해도 이번 실행에서는 고른 값을 쓰며, 그때 false.
  /// 내장 칸은 고유 설정이 없어 바꿀 수 없다([UnsupportedError]).
  Future<bool> setCardCount(int count) => _set(
    (s) => s.copyWith(cardCount: count),
    (decks, deckId) => decks.saveCardCount(deckId, count),
  );

  Future<bool> setQuizCount(int count) => _set(
    (s) => s.copyWith(quizCount: count),
    (decks, deckId) => decks.saveQuizCount(deckId, count),
  );

  Future<bool> _set(
    DeckSettings Function(DeckSettings) change,
    Future<void> Function(StudyDecks decks, int deckId) save,
  ) async {
    final deck = this.deck;
    if (deck is! StudyDeck) {
      throw UnsupportedError('내장 칸은 고유 설정이 없다');
    }
    final decks = ref.read(studyDecksProvider);
    await future;
    // await 뒤에 바로 현재 값을 읽어 바꾼다 — 잇달아 불러도 서로의 값을 덮어쓰지 않는다.
    // 버려진 notifier의 state는 건드리지 않되, 저장은 끝까지 한다
    if (ref.mounted) state = AsyncData(change(state.requireValue));
    try {
      await save(decks, deck.deckId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
