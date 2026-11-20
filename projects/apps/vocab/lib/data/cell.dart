/// 학교급.
enum SchoolLevel {
  elementary('초등'),
  middle('중등'),
  high('고등');

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

/// 내장 단어장의 칸(학교급 × 난이도 = 9칸). 칸마다 단어 파일이 하나씩 있다.
enum Cell {
  elementaryEasy(SchoolLevel.elementary, Difficulty.easy),
  elementaryMedium(SchoolLevel.elementary, Difficulty.medium),
  elementaryHard(SchoolLevel.elementary, Difficulty.hard),
  middleEasy(SchoolLevel.middle, Difficulty.easy),
  middleMedium(SchoolLevel.middle, Difficulty.medium),
  middleHard(SchoolLevel.middle, Difficulty.hard),
  highEasy(SchoolLevel.high, Difficulty.easy),
  highMedium(SchoolLevel.high, Difficulty.medium),
  highHard(SchoolLevel.high, Difficulty.hard);

  const Cell(this.level, this.difficulty);

  final SchoolLevel level;
  final Difficulty difficulty;

  /// 칸마다 목표 단어 수(명세: 칸당 50개).
  static const int targetWordCount = 50;

  /// 파일 이름·주소에 쓰는 이름. 예: `elementary_easy`.
  String get id => '${level.name}_${difficulty.name}';

  /// 화면 제목에 보이는 이름. 예: `중등 [난이도 : 중간]`(2026-11-20 사용자 결정).
  /// 안쪽 화면 제목은 여기에 ` - 시험`처럼 붙인다.
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
