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
/// - 오답 보기 3개는 같은 칸의 다른 단어에서 무작위로(명세). **화면에 보이는 글자가 정답과도, 서로도 겹치지
///   않는 것만** 고른다 — 내 단어장에는 뜻이나 영단어가 같은 단어가 들어올 수 있고, 같은 글자의 보기가 둘이면
///   맞는 글자를 골라도 틀림이 된다
///
/// `pool`을 주면 오답 보기를 거기서 고른다 — 오답 시험은 노트 단어(`words`)만 묻되 보기는 칸 전체에서(명세: 같은 칸).
///
/// 낼 단어가 없거나 보기 후보로 시험을 낼 수 없으면([quizBlockReason]) 빈 목록을 돌려준다.
List<QuizQuestion> buildQuiz(
  List<Word> words,
  Random random, {
  int length = quizLength,
  List<Word>? pool,
}) {
  final choices = pool ?? words;
  if (words.isEmpty || quizBlockReason(choices) != null) return const [];
  final order = [...words]..shuffle(random);
  return [
    for (final word in order.take(length))
      _question(word, QuizDirection.values[random.nextInt(2)], choices, random),
  ];
}

QuizQuestion _question(
  Word word,
  QuizDirection direction,
  List<Word> choices,
  Random random,
) {
  String text(Word w) =>
      direction == QuizDirection.wordToMeaning ? w.meaning : w.word;
  final seen = {text(word)};
  final options = [word];
  // quizBlockReason을 지났으므로 글자가 다른 후보가 반드시 3개 이상 있다
  for (final candidate in [...choices]..shuffle(random)) {
    if (options.length == quizOptionCount) break;
    if (seen.add(text(candidate))) options.add(candidate);
  }
  return QuizQuestion(
    word: word,
    direction: direction,
    options: options..shuffle(random),
  );
}

/// 이 단어들로 시험을 낼 수 없는 까닭(화면 안내 문구). 낼 수 있으면 null.
///
/// 어느 방향으로든 보기 4개의 글자가 서로 달라야 하므로, 서로 다른 영단어와 서로 다른 뜻이
/// 각각 [quizOptionCount]개 이상 있어야 한다. 내장 칸은 단어 파일 검사 시험이 이것을 보장한다.
String? quizBlockReason(List<Word> pool) {
  if (pool.length < quizOptionCount) {
    return '단어가 $quizOptionCount개 이상 있어야 시험을 볼 수 있습니다';
  }
  final words = {for (final w in pool) w.word};
  final meanings = {for (final w in pool) w.meaning};
  if (words.length < quizOptionCount || meanings.length < quizOptionCount) {
    return '영단어와 뜻이 서로 다른 단어가 $quizOptionCount개 이상 있어야 시험을 볼 수 있습니다';
  }
  return null;
}

/// 시험을 섞는 데 쓰는 난수. 시험(test)에서는 씨앗을 정한 것으로 바꿔 결과를 고정한다.
final quizRandomProvider = Provider<Random>((ref) => Random());
