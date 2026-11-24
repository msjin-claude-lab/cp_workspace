/// 한 문제의 보기에 함께 나오면 정답이 둘로 보이는 영단어 쌍. 세 종류다:
/// 뜻이 거의 같은 쌍(dad/father), 어원이 같은 쌍(invent/invention, quick/quickly — 2026-11-24
/// 사용자 결정 "어원 같은 쌍은 모두 넣는다"), 우리말 뜻 글자가 같은 동음이의어 쌍(stomach/pear 배).
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
  // 중등 쉬움(2026-11-24 검토)
  ('mum', 'mommy'),
  ('grandma', 'granny'),
  ('police', 'policeman'),
  ('pasta', 'spaghetti'),
  ('soda', 'cola'),
  ('ski', 'skiing'),
  ('skate', 'skating'),
  ('hike', 'hiking'),
  ('hiking', 'climbing'),
  ('drawing', 'painting'),
  ('exam', 'quiz'),
  ('lose', 'lost'),
  ('fry', 'fried'),
  ('stomach', 'pear'), // 위·배 / 배(과일)
  // 중등 중간(2026-11-24 검토)
  ('kilo', 'kilogram'),
  ('kilo', 'kilometer'),
  ('Olympic', 'Olympics'),
  ('shut', 'closed'),
  ('storm', 'thunderstorm'),
  ('photograph', 'photography'),
  ('excellent', 'fantastic'),
  ('tourist', 'traveler'),
  ('mad', 'crazy'),
  ('sunlight', 'daylight'),
  ('web', 'website'),
  ('shout', 'scream'),
  // 중등 어려움(2026-11-24 검토)
  ('alive', 'living'),
  ('coast', 'shore'),
  ('skill', 'technology'),
  ('fear', 'horror'),
  ('recently', 'nowadays'),
  ('nervous', 'worried'),
  ('pleasure', 'happiness'),
  ('explain', 'describe'),
  ('receive', 'accept'),
  ('contest', 'championship'),
  ('invent', 'create'),
  ('invent', 'invention'),
  ('fool', 'trick'),
  ('item', 'stuff'),
  ('trouble', 'difficulty'),
  ('director', 'manager'),
  ('pleased', 'pleasure'),
  ('suggest', 'suggestion'),
  ('celebrate', 'celebration'),
  ('pronounce', 'pronunciation'),
  ('rent', 'lend'),
  ('relaxed', 'comfortable'),
  ('tip', 'advice'),
  ('skill', 'talent'),
  // 어원이 같은 쌍(2026-11-24 두 축 검토 — 사용자 결정 "모두 넣는다")
  ('quick', 'quickly'), // 중등 쉬움
  ('bicycle', 'cycling'), // 중등 쉬움
  ('tour', 'tourist'), // 중등 중간
  ('power', 'powerful'), // 중등 어려움
  ('crowd', 'crowded'), // 중등 어려움
  ('interview', 'interviewer'), // 중등 어려움
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
