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
  // 고등 쉬움 앞 300개(2026-11-24 검토) — 뜻이 거의 같음
  ('perhaps', 'probably'),
  ('perhaps', 'possibly'),
  ('probably', 'possibly'),
  ('disease', 'illness'),
  ('appear', 'seem'),
  ('normal', 'ordinary'),
  ('usual', 'normal'),
  ('mainly', 'mostly'),
  ('fact', 'truth'),
  ('provide', 'offer'),
  ('increase', 'rise'),
  ('reach', 'achieve'),
  ('protect', 'guard'),
  ('loss', 'damage'), // 손실 / 손상
  ('war', 'battle'),
  ('total', 'whole'),
  ('stress', 'pressure'),
  ('explanation', 'description'),
  ('professional', 'expert'),
  ('recent', 'latest'),
  ('completely', 'perfectly'),
  ('quite', 'extremely'), // 아주 / 매우
  ('global', 'international'),
  ('zone', 'area'),
  ('vehicle', 'transportation'), // 탈것 / 교통수단
  ('main', 'central'), // 주요한 / 중요한
  ('certainly', 'clearly'), // 확실히 / 분명히
  ('ahead', 'forward'), // 앞에 / 앞으로
  // 고등 쉬움 앞 300개 — 어원이 같음
  ('center', 'central'),
  ('sudden', 'suddenly'),
  ('deliver', 'delivery'),
  ('natural', 'naturally'),
  ('normal', 'normally'),
  ('regular', 'regularly'),
  ('serious', 'seriously'),
  ('clear', 'clearly'),
  ('complete', 'completely'),
  ('perform', 'performance'),
  ('produce', 'production'),
  ('produce', 'product'),
  ('product', 'production'),
  ('express', 'expression'),
  ('include', 'including'),
  ('fail', 'failure'),
  ('main', 'mainly'),
  ('able', 'ability'),
  ('able', 'unable'),
  ('value', 'valuable'),
  ('silence', 'silent'),
  ('national', 'international'),
  ('cent', 'percent'),
  ('electricity', 'electronic'),
  ('search', 'research'),
  ('less', 'least'),
  ('possible', 'possibly'),
  ('truth', 'truly'), // true
  ('knowledge', 'unknown'), // know
  ('ever', 'whenever'),
  ('more', 'mostly'), // much·more·most
  ('however', 'ever'),
  ('experience', 'experiment'),
  ('pressure', 'express'), // press
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
