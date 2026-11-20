/// 내장 단어 하나. 명세의 단어 필드: 영단어, 뜻, 예문 + 예문 해석(2026-11-20 사용자 결정).
class Word {
  const Word({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.exampleMeaning,
  });

  /// 칸 안에서 겹치지 않는 번호. 학습 기록·오답 노트가 이 값으로 단어를 가리킨다.
  final String id;
  final String word;
  final String meaning;
  final String example;

  /// 예문의 우리말 해석. 카드 뒷면·시험 정답 화면에서 예문 아래에 보여 준다.
  final String exampleMeaning;

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'] as String,
        word: json['word'] as String,
        meaning: json['meaning'] as String,
        example: json['example'] as String,
        exampleMeaning: json['exampleMeaning'] as String,
      );
}
