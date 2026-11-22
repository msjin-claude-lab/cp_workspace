/// 카드 학습 한 회차의 기본 단어 수(2026-11-22 사용자 결정).
const int defaultCardCount = 50;

/// 시험 한 회차의 기본 문항 수. 난이도와 상관없이 20(2026-11-20 사용자 결정 — 보편적인 방식, 난이도는 단어로 조절).
const int defaultQuizCount = 20;

/// 설정 화면에서 바로 고르는 수(카드 학습·시험 공통). 이 밖의 수는 "직접 입력"으로 넣는다.
const List<int> countChoices = [10, 20, 30, 50];

/// 직접 입력으로 넣을 수 있는 범위(2026-11-22 사용자 결정 — "단어 수랑 문항 수에 직접 입력 항목도 추가").
const int minCount = 1;
const int maxCount = 999;

/// 카드·시험 수로 쓸 수 있는 값인가. 저장된 값이 이 밖이면 기본값으로 본다.
bool isValidCount(int? n) => n != null && n >= minCount && n <= maxCount;
