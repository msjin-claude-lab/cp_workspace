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
  easy('하'),
  medium('중'),
  hard('상');

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

  /// 화면에 보이는 이름. 예: `초등 · 하`.
  String get label => '${level.label} · ${difficulty.label}';

  String get assetPath => 'assets/words/$id.json';

  static Cell of(SchoolLevel level, Difficulty difficulty) =>
      values.firstWhere((c) => c.level == level && c.difficulty == difficulty);
}
