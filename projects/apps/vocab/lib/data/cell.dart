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

/// 카드 학습·시험·오답 노트를 할 단어 묶음: 내장 칸([Cell]) 또는 내 단어장([BookDeck]).
/// 화면은 이것 하나로 둘 다 다룬다. 기록 표의 `cell_id`에는 [id]가 들어간다.
sealed class Deck {
  /// 기록 표(`study_log`·`quiz_log`·`wrong_notes`)의 `cell_id`이자 주소에 쓰는 이름.
  /// 칸은 `elementary_easy`, 내 단어장은 `book_3` — 서로 겹치지 않는다.
  String get id;

  /// 화면 제목. 안쪽 화면은 여기에 ` - 시험`처럼 붙인다.
  String get label;
}

/// 내 단어장 하나. 같은 단어장인지는 번호로만 본다 — 이름을 바꿔도 같은 묶음이다.
///
/// [Cell.byId]는 `book_N`을 모르므로 null을 돌려준다. 그래서 내 단어장 기록은
/// 진도 화면과 학교급별 오답 노트에 섞이지 않는다.
final class BookDeck implements Deck {
  const BookDeck({required this.bookId, required this.name});

  final int bookId;
  final String name;

  static const String _prefix = 'book_';

  @override
  String get id => '$_prefix$bookId';

  /// 제목은 단어장 이름(2026-11-20 사용자 결정 — `<이름> - 시험` 꼴).
  @override
  String get label => name;

  /// `book_3` → 3. 내 단어장 id가 아니면 null.
  static int? parseId(String id) => id.startsWith(_prefix)
      ? int.tryParse(id.substring(_prefix.length))
      : null;

  @override
  bool operator ==(Object other) => other is BookDeck && other.bookId == bookId;

  @override
  int get hashCode => bookId.hashCode;
}

/// 내장 단어장의 칸(학교급 × 난이도 = 9칸). 칸마다 단어 파일이 하나씩 있다.
enum Cell implements Deck {
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
