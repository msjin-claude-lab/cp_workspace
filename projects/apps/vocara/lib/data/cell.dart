/// 학교급.
enum SchoolLevel {
  elementary('초등'),
  middle('중등'),
  high('고등'),
  advanced('심화');

  const SchoolLevel(this.label);

  final String label;
}

/// 난이도.
enum Difficulty {
  // 화면 이름은 쉬움·중간·어려움(2026-11-20 사용자 결정 — 전에는 하·중·상)
  easy('쉬움'),
  medium('중간'),
  hard('어려움');

  const Difficulty(this.label);

  final String label;
}

/// 카드 학습·시험·오답 노트를 할 단어 묶음: 내장 칸([Cell]) 또는 이름 있는 단어장([StudyDeck]).
/// 화면은 이것 하나로 모두 다룬다. 기록 표의 `cell_id`에는 [id]가 들어간다.
sealed class Deck {
  /// 기록 표(`study_log`·`quiz_log`·`wrong_notes`)의 `cell_id`이자 주소에 쓰는 이름.
  /// 칸은 `elementary_easy`, 이름 있는 단어장은 `deck_2` — 서로 겹치지 않는다.
  String get id;

  /// 화면 제목. 안쪽 화면은 여기에 ` - 시험`처럼 붙인다.
  String get label;
}

/// 이름 있는 단어장 하나: 사용자가 이름을 짓고 학교급 → 난이도를 골라 만든다(2026-11-22 사용자 결정 —
/// "새 등록"은 무조건 새 단어장을 만들고, 같은 학교급+난이도도 여러 개 만들 수 있다).
///
/// 단어는 바탕 칸([base])의 단어 파일에서 읽고, 기록은 `cell_id = deck_<번호>`로 따로 쌓는다 —
/// 같은 칸으로 만든 단어장끼리도 학습 기록·오답 노트·진도가 섞이지 않는다.
/// 같은 단어장인지는 번호로만 본다(이름을 바꿔도 같은 단어장).
final class StudyDeck implements Deck {
  const StudyDeck({
    required this.deckId,
    required this.name,
    required this.base,
  });

  final int deckId;
  final String name;

  /// 단어를 가져오는 칸(학교급 + 난이도).
  final Cell base;

  static const String _prefix = 'deck_';

  /// [Cell.byId]는 `deck_N`을 모르므로 null을 돌려준다.
  @override
  String get id => idOf(deckId);

  /// 단어장 번호의 id 문자열(`2` → `deck_2`).
  static String idOf(int deckId) => '$_prefix$deckId';

  /// 제목은 단어장 이름(`<이름> - 시험` 꼴).
  @override
  String get label => name;

  /// `deck_2` → 2. 이름 있는 단어장 id가 아니면 null.
  static int? parseId(String id) => id.startsWith(_prefix)
      ? int.tryParse(id.substring(_prefix.length))
      : null;

  StudyDeck renamed(String name) =>
      StudyDeck(deckId: deckId, name: name, base: base);

  @override
  bool operator ==(Object other) =>
      other is StudyDeck && other.deckId == deckId;

  @override
  int get hashCode => deckId.hashCode;
}

/// 내장 단어장의 칸(학교급 × 난이도 = 12칸). 칸마다 단어 파일이 하나씩 있다.
enum Cell implements Deck {
  elementaryEasy(SchoolLevel.elementary, Difficulty.easy),
  elementaryMedium(SchoolLevel.elementary, Difficulty.medium),
  elementaryHard(SchoolLevel.elementary, Difficulty.hard),
  middleEasy(SchoolLevel.middle, Difficulty.easy),
  middleMedium(SchoolLevel.middle, Difficulty.medium),
  middleHard(SchoolLevel.middle, Difficulty.hard),
  highEasy(SchoolLevel.high, Difficulty.easy),
  highMedium(SchoolLevel.high, Difficulty.medium),
  highHard(SchoolLevel.high, Difficulty.hard),
  advancedEasy(SchoolLevel.advanced, Difficulty.easy),
  advancedMedium(SchoolLevel.advanced, Difficulty.medium),
  advancedHard(SchoolLevel.advanced, Difficulty.hard);

  const Cell(this.level, this.difficulty);

  final SchoolLevel level;
  final Difficulty difficulty;

  /// 파일 이름·주소에 쓰는 이름. 예: `elementary_easy`.
  @override
  String get id => '${level.name}_${difficulty.name}';

  /// 화면 제목에 보이는 이름. 예: `중등 [난이도 : 중간]`(2026-11-20 사용자 결정).
  /// 안쪽 화면 제목은 여기에 ` - 시험`처럼 붙인다.
  @override
  String get label => '${level.label} [난이도 : ${difficulty.label}]';

  String get assetPath => 'assets/words/$id.json';

  static Cell of(SchoolLevel level, Difficulty difficulty) =>
      values.firstWhere((c) => c.level == level && c.difficulty == difficulty);

  /// `id`로 칸을 찾는다. 없으면 null(잘못된 주소).
  static Cell? byId(String id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
