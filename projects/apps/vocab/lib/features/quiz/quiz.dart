import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/word.dart';

/// 문제 방향.
enum QuizDirection {
  /// 영단어를 보고 뜻을 고른다.
  wordToMeaning,

  /// 뜻을 보고 영단어를 고른다.
  meaningToWord,
}

/// 4지선다 한 문제. 보기 4개 중 하나가 정답(`word`)이다.
class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.direction,
    required this.options,
  });

  final Word word;
  final QuizDirection direction;

  /// 보기 4개(정답 포함, 섞인 순서).
  final List<Word> options;

  int get answerIndex => options.indexOf(word);

  /// 문제로 보여 줄 글자.
  String get prompt =>
      direction == QuizDirection.wordToMeaning ? word.word : word.meaning;

  /// 보기로 보여 줄 글자.
  String optionText(Word option) =>
      direction == QuizDirection.wordToMeaning ? option.meaning : option.word;
}

/// 한 번에 내는 문제 수. 난이도와 상관없이 20(2026-11-20 사용자 결정 — 보편적인 방식, 난이도는 단어로 조절).
/// 단어는 앞으로 영단어 책 수준으로 늘릴 예정이라 "전부" 같은 선택지는 두지 않는다.
const int quizLength = 20;

/// 보기 수. 단어가 이보다 적은 칸은 시험을 낼 수 없다(명세: 내 단어장은 4개 이상이면 시험 가능).
const int quizOptionCount = 4;

/// 칸의 단어로 시험을 만든다. 부를 때마다 새로 섞는다(사용자 결정).
///
/// - 단어 순서를 섞어 앞에서 `length`개(단어가 적으면 전부)를 문제로 낸다 — 한 회차에 같은 단어는 한 번만
/// - 방향(영→뜻, 뜻→영)은 문제마다 무작위
/// - 오답 보기 3개는 같은 칸의 다른 단어에서 무작위로(명세). 같은 칸에는 같은 뜻이 없다(단어 파일 검사 시험)
///
/// `pool`을 주면 오답 보기를 거기서 고른다 — 오답 시험은 노트 단어(`words`)만 묻되 보기는 칸 전체에서(명세: 같은 칸).
/// `pool`의 단어 객체는 `words`와 같은 것이어야 한다(정답을 보기 후보에서 빼려고 같은 객체인지로 비교).
///
/// 보기 후보가 [quizOptionCount]개보다 적거나 낼 단어가 없으면 빈 목록을 돌려준다.
List<QuizQuestion> buildQuiz(
  List<Word> words,
  Random random, {
  int length = quizLength,
  List<Word>? pool,
}) {
  final choices = pool ?? words;
  if (words.isEmpty || choices.length < quizOptionCount) return const [];
  final order = [...words]..shuffle(random);
  return [
    for (final word in order.take(length))
      QuizQuestion(
        word: word,
        direction: QuizDirection.values[random.nextInt(2)],
        options: [
          word,
          ...([...choices]
                ..remove(word)
                ..shuffle(random))
              .take(quizOptionCount - 1),
        ]..shuffle(random),
      ),
  ];
}

/// 시험을 섞는 데 쓰는 난수. 시험(test)에서는 씨앗을 정한 것으로 바꿔 결과를 고정한다.
final quizRandomProvider = Provider<Random>((ref) => Random());
