/// 뜻이 거의 같아 한 문제의 보기에 함께 나오면 정답이 둘로 보이는 영단어 쌍.
///
/// 시험은 한 문제의 보기 4개에 쌍을 함께 내지 않는다(2026-11-23 사용자 결정 —
/// 뜻 글자를 고쳐도 풀리지 않아 단어는 그대로 두고 보기에서만 가른다). 둘 다 그 회차의 문제로
/// 나오는 것은 막지 않는다. 쌍의 두 단어가 같은 칸에 있는지는 `test/data/similar_words_test.dart`가 본다.
const List<(String, String)> similarWordPairs = [
  // 초등 쉬움
  ('dad', 'father'),
  ('mom', 'mother'),
  ('little', 'small'),
  ('house', 'home'),
  ('hat', 'cap'),
  ('pretty', 'beautiful'),
  ('see', 'look'),
  ('hear', 'listen'),
  ('say', 'speak'),
  ('dish', 'bowl'),
  // 초등 중간
  ('much', 'lot'),
  // 초등 어려움
  ('smart', 'clever'),
  ('wonderful', 'super'),
  ('still', 'yet'),
  ('waiter', 'waitress'),
];

final Map<String, Set<String>> _partners = () {
  final map = <String, Set<String>>{};
  for (final (a, b) in similarWordPairs) {
    map.putIfAbsent(a, () => {}).add(b);
    map.putIfAbsent(b, () => {}).add(a);
  }
  return map;
}();

/// 두 영단어가 [similarWordPairs]의 한 쌍인가.
bool areSimilarWords(String a, String b) => _partners[a]?.contains(b) ?? false;
