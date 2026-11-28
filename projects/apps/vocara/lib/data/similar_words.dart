/// 한 문제의 보기에 함께 나오면 정답이 둘로 보이는 영단어 쌍. 세 종류다:
/// 뜻이 거의 같은 쌍(dad/father), 어원이 같은 쌍(invent/invention, quick/quickly — 2026-11-24
/// 사용자 결정 "어원 같은 쌍은 모두 넣는다" — 접두·접미사로 이어진 파생어만. 합성어라 뜻이 뚜렷이
/// 다른 쌍(bookcase/bookshop, left-hand/handbag)은 넣지 않는다, 2026-11-24 사용자 결정), 우리말 뜻 글자가 같은 동음이의어 쌍(stomach/pear 배).
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
  // 고등 쉬움 301~500(2026-11-24 검토) — 뜻이 거의 같음
  ('amazing', 'incredible'),
  ('cop', 'policewoman'),
  ('though', 'although'),
  ('totally', 'completely'),
  ('universe', 'space'),
  ('scenery', 'view'),
  ('ingredient', 'material'),
  ('growth', 'increase'), // 증대 / 증가
  ('used', 'familiar'), // ~에 익숙한 / 익숙한
  ('major', 'main'),
  ('award', 'prize'),
  ('global', 'worldwide'),
  ('behavior', 'act'), // 행동 / 행동하다
  ('latest', 'update'), // 최신의 / 최신 정보
  ('contact', 'communicate'),
  ('opposite', 'against'),
  ('view', 'opinion'), // 관점 / 견해
  ('divide', 'separate'),
  ('certain', 'clear'),
  ('certain', 'positive'), // 확실한 / 확신하는
  ('though', 'however'),
  ('however', 'although'), // 하지만 / ~이긴 하지만(5단계 표본 검토)
  ('cigarette', 'smoke'),
  ('cigarette', 'smoking'),
  ('petrol', 'fuel'),
  ('silently', 'softly'),
  ('perform', 'manage'), // 해내다 / 간신히 해내다
  // 고등 쉬움 301~500 — 어원이 같음
  ('scene', 'scenery'),
  ('anger', 'angrily'),
  ('smoke', 'smoking'),
  ('kill', 'killer'),
  ('research', 'researcher'),
  ('silent', 'silently'),
  ('silence', 'silently'),
  ('safety', 'safely'),
  ('shock', 'shocked'),
  ('stress', 'stressed'),
  ('certain', 'certainly'),
  ('fortunately', 'unfortunately'),
  ('importance', 'unimportant'),
  ('total', 'totally'),
  ('satisfy', 'satisfied'),
  ('act', 'active'),
  ('pain', 'painful'),
  ('drug', 'drugstore'),
  ('space', 'spaceship'),
  ('weekly', 'weekday'), // week
  ('unknown', 'well-known'), // know
  ('nearly', 'nearby'), // near
  // 고등 쉬움 301~500 — 우리말 뜻 글자가 같은 동음이의어
  ('smoke', 'act'), // 연기 / 연기하다
  ('truly', 'calm'), // 진정으로 / 진정시키다
  ('mostly', 'replace'), // 대체로 / 대체하다
  // 고등 중간 앞 300개(2026-11-24 검토) — 뜻이 거의 같음
  ('maximum', 'max'),
  ('vast', 'enormous'),
  ('enormous', 'massive'),
  ('vast', 'massive'),
  ('vast', 'broad'), // 광대한 / 넓은
  ('broad', 'widely'), // 폭넓은 / 폭넓게
  ('beat', 'defeat'),
  ('complaint', 'protest'), // 항의 / 항의하다
  ('aim', 'target'), // 목표로 하다 / 목표
  ('suitable', 'proper'),
  ('suitable', 'fit'),
  ('proper', 'fit'), // 적절한 / 알맞다
  ('aside', 'apart'),
  ('apart', 'besides'), // apart from / ~외에도
  ('distant', 'remote'),
  ('immediate', 'instant'),
  ('constantly', 'continuous'), // 끊임없이 / 끊임없는
  ('continuous', 'steady'),
  ('generally', 'commonly'),
  ('generally', 'typically'), // 보통 / 보통은
  ('commonly', 'typically'),
  ('largely', 'generally'),
  ('obviously', 'definitely'), // 분명히 / 확실히
  ('greatly', 'highly'), // 몹시 / 대단히
  ('link', 'connection'), // 관련성 / 관련
  ('source', 'root'), // 근원 / 근본
  ('argument', 'debate'),
  ('lack', 'absence'),
  ('risk', 'threat'), // 위험 / 위협
  ('nation', 'citizen'), // 국민 / 시민
  ('exhibition', 'display'), // 전시 / 전시하다
  ('admit', 'recognize'), // 인정하다
  ('rarely', 'hardly'),
  ('equipment', 'instrument'), // 기구 / 도구
  ('expense', 'fee'), // 비용 / 요금
  ('developed', 'advanced'), // 선진의 / 발전된
  ('spirit', 'soul'), // 정신 / 영혼
  ('arrest', 'capture'), // 체포하다 / 붙잡다
  ('logical', 'reasonable'), // 타당한 / 합리적인
  ('instruction', 'command'), // 지시 / 명령
  ('entry', 'participate'), // 참가 / 참가하다
  ('operate', 'surgery'), // 수술하다 / 수술
  ('environmental', 'setting'), // 환경의 / 환경
  ('practical', 'reality'), // 현실적인 / 현실
  ('progress', 'advanced'), // 진보 / 진보한
  ('spirit', 'mental'), // 정신 / 정신의
  // 고등 중간 앞 300개 — 어원이 같음
  ('direct', 'directly'),
  ('proper', 'properly'),
  ('rapid', 'rapidly'),
  ('obvious', 'obviously'),
  ('frequent', 'frequently'),
  ('automatic', 'automatically'),
  ('typical', 'typically'),
  ('recover', 'recovery'),
  ('violent', 'violence'),
  ('religion', 'religious'),
  ('physical', 'physics'),
  ('lead', 'leadership'),
  ('organ', 'organic'),
  ('organ', 'organized'), // organize
  ('organic', 'organized'),
  ('respond', 'responsible'), // response
  ('minor', 'minimum'), // min-
  ('visual', 'visible'), // vis-
  ('nation', 'native'), // nat-
  ('definition', 'definitely'), // define
  ('structure', 'destruction'), // struct-
  ('structure', 'instruction'), // struct-
  ('destruction', 'instruction'), // struct-
  ('likely', 'unlike'), // like
  // 고등 중간 앞 300개 — 우리말 뜻 글자가 같은 동음이의어
  ('suppose', 'household'), // 가정하다(假定) / 가정(家庭)
  // 고등 중간 301~500·칸 전체(2026-11-24 검토) — 뜻이 거의 같음
  ('refuse', 'reject'), // 거절하다 / 거부하다
  ('respond', 'react'), // 반응하다 / 반응을 보이다
  ('remedy', 'cure'), // 치료법 / 치료제
  ('cure', 'heal'), // 낫게 하다 / 낫다
  ('remedy', 'heal'), // 치료법 / 치유하다
  ('reasonable', 'inexpensive'), // (가격이) 비싸지 않은 / 저렴한
  ('respect', 'admire'), // 존경 / 존경하다
  ('respect', 'admiration'), // 존경 / 존경심
  ('disabled', 'handicapped'), // 장애가 있는 / 장애를 가진
  ('entertainment', 'amusement'), // 오락 / 재미·즐거움
  ('shame', 'pity'), // 안타까운 일 / 유감
  ('jealous', 'envy'), // 시기하는 / 부러워하다
  ('bother', 'annoy'), // 귀찮게 하다 / 성가시게 하다
  ('bother', 'disturb'), // 귀찮게 하다 / 방해하다
  ('disturb', 'interrupt'), // 방해하다 / 가로막다
  ('frighten', 'terrify'), // 겁먹게 하다 / 겁에 질리게 하다
  ('frightening', 'terrify'), // 무서운 / 무섭게 하다
  ('frightened', 'terrify'), // 겁먹은 / 겁에 질리게 하다
  ('inspire', 'motivate'), // 격려하다 / 의욕을 북돋우다
  ('inspiration', 'motivation'), // 자극 / 동기 부여
  ('inspiration', 'motivate'), // 자극 / 자극하다
  ('blame', 'fault'), // 탓하다 / 탓
  ('fare', 'fee'), // 운임 / 요금
  ('disadvantage', 'weakness'), // 단점 / 약점
  ('destruction', 'ruin'), // 파멸 / 파멸시키다
  ('crop', 'harvest'), // 수확량 / 수확
  ('grab', 'capture'), // 붙들다 / 붙잡다
  ('fascinating', 'attractive'), // 매혹적인 / 매력적인
  ('practical', 'realistic'), // 현실적인 / 현실성 있는
  ('anxious', 'uneasy'), // 불안한 / 마음이 놓이지 않는
  ('anxious', 'eager'), // 간절히 바라는 / 몹시 하고 싶어 하는
  ('frank', 'honesty'), // 솔직한 / 솔직함
  ('elderly', 'senior'), // 나이 든 / 연장자
  ('advanced', 'fancy'), // 고급의 / 고급스러운
  ('spirit', 'lively'), // 활기 / 활기찬
  ('nuclear', 'atom'), // 원자력의 / 원자
  ('fiction', 'romance'), // 소설 / 연애 소설
  ('entry', 'participant'), // 참가 / 참가자
  // 고등 중간 301~500·칸 전체 — 어원이 같음
  ('motivation', 'motivate'),
  ('inspiration', 'inspire'),
  ('admiration', 'admire'),
  ('ambition', 'ambitious'),
  ('invasion', 'invade'),
  ('shame', 'ashamed'),
  ('frustration', 'frustrated'),
  ('rob', 'robbery'),
  ('honesty', 'dishonest'),
  ('patience', 'impatient'),
  ('amusement', 'amused'),
  ('frighten', 'frightened'),
  ('frighten', 'frightening'),
  ('frightened', 'frightening'),
  ('impressive', 'impress'),
  ('impression', 'impressive'),
  ('impression', 'impress'),
  ('physical', 'physically'),
  ('physics', 'physically'),
  ('strength', 'strengthen'),
  ('attractive', 'attract'),
  ('participate', 'participant'),
  ('assignment', 'assign'),
  ('appointment', 'appoint'),
  ('retired', 'retire'),
  ('warning', 'warn'),
  ('survival', 'survivor'),
  ('injury', 'injure'),
  ('punishment', 'punish'),
  ('summary', 'summarize'),
  ('smooth', 'smoothly'),
  ('rough', 'roughly'),
  ('advertising', 'advertise'),
  ('confusion', 'confuse'),
  ('combination', 'combine'),
  ('politics', 'politician'),
  ('historical', 'historian'),
  ('reality', 'realistic'),
  ('likely', 'unlikely'),
  ('unlike', 'unlikely'), // like
  ('pleasant', 'unpleasant'),
  ('pleasant', 'pleasing'), // please
  ('expense', 'inexpensive'), // expensive
  ('base', 'basically'), // basic
  // 고등 어려움 앞 300개(2026-11-24 검토) — 뜻이 거의 같음
  ('thus', 'therefore'), // 따라서 / 그러므로
  ('thus', 'consequently'), // 따라서 / 결과적으로
  ('therefore', 'consequently'), // 그러므로 / 그 결과
  ('moreover', 'furthermore'), // 게다가 / 더욱이
  ('further', 'additional'), // 더 이상의 / 추가적인
  ('considerable', 'substantial'), // 상당한 / 상당량의
  ('significant', 'considerable'), // (양·정도가) 상당한 / 상당한
  ('significant', 'substantial'), // (양·정도가) 상당한 / 상당량의
  ('significant', 'critical'), // 중요한 / 중대한
  ('significant', 'principal'), // 중요한 / 주요한
  ('influence', 'affect'), // 영향 / 영향을 미치다
  ('influence', 'impact'), // 영향 / (강한) 영향
  ('impact', 'affect'), // (강한) 영향 / 영향을 미치다
  ('obtain', 'gain'), // 획득하다 / 얻다
  ('gain', 'benefit'), // 이득 / 이익
  ('occur', 'arise'), // 발생하다 / 생기다
  ('apparent', 'evident'), // 명백한 / 분명한
  ('presence', 'existence'), // 있음 / 존재
  ('being', 'existence'), // 존재하는 것 / 존재
  ('potential', 'possibility'), // 잠재력 / 가능성
  ('possibility', 'probability'), // 가능성 / 개연성
  ('demand', 'require'), // 요구하다 / (규칙으로) 요구하다
  ('fund', 'finance'), // 자금을 대다 / 자금을 조달하다
  ('committee', 'council'), // 위원회 / 협의회
  ('feature', 'characteristic'), // 특징 / 특성
  ('property', 'characteristic'), // (물질의) 성질 / 특성
  ('property', 'possession'), // 재산 / 소유물
  ('property', 'wealth'), // 재산 / 부
  ('degree', 'extent'), // 정도 / (to some extent) 어느 정도
  ('occupation', 'profession'), // 직업 / 전문직
  ('basis', 'foundation'), // 기초 / 토대
  ('association', 'institute'), // 협회 / 학회
  ('agency', 'organization'), // 기관 / 기구
  ('administration', 'management'), // 운영 / 관리
  ('despite', 'nevertheless'), // ~에도 불구하고 / 그럼에도 불구하고
  ('represent', 'indicate'), // 표현하다 / 나타내다
  ('refer', 'indicate'), // 지칭하다 / 가리키다
  ('state', 'status'), // 상태 / (진행) 상황
  ('position', 'status'), // 직위 / 지위
  ('security', 'stable'), // 안정 / 안정된
  ('decline', 'reduction'), // 감소하다 / 감소
  ('composition', 'constitute'), // 구성 / 구성하다
  ('establish', 'foundation'), // 설립하다 / 설립
  ('claim', 'maintain'), // 주장하다 / (계속) 주장하다
  ('concern', 'involved'), // 관련되다 / 관련된
  ('concerned', 'involved'), // ~와 관련된 / 관련된
  ('relation', 'involved'), // 관련 / 관련된
  ('relation', 'concern'), // 관련 / 관련되다
  ('consideration', 'reflect'), // 숙고 / 숙고하다
  ('function', 'operation'), // 작동하다 / 작동
  ('process', 'treatment'), // 처리하다 / 처리
  ('absolute', 'fully'), // 완전한 / 완전히
  ('fully', 'sufficient'), // 충분히 / 충분한
  ('appropriate', 'moderate'), // 적절한 / 적당한
  ('superior', 'outstanding'), // 우수한 / 뛰어난
  ('distinction', 'outstanding'), // 뛰어남 / 뛰어난
  ('distinction', 'discrimination'), // 구별 / 식별
  ('wisdom', 'intelligence'), // 지혜 / 지성
  ('spiritual', 'psychological'), // 정신적인 / 심리적인
  ('effective', 'efficiency'), // 효과적인 / 효율
  ('capable', 'capacity'), // 유능한 / 능력
  ('intention', 'objective'), // 목적 / 목표
  ('otherwise', 'unless'), // 그렇지 않으면 / ~하지 않으면
  ('presence', 'attend'), // 출석 / 참석하다
  ('relatively', 'comparative'), // 비교적 / 비교의
  ('mutual', 'interaction'), // 상호의 / 상호 작용
  ('contrary', 'objection'), // 반대의 / 반대
  ('contrary', 'object'), // 반대의 / (object to) ~에 반대하다
  // 고등 어려움 앞 300개 — 어원이 같음(further/furthermore는 합성어라 넣지 않음)
  ('state', 'statement'),
  ('industry', 'industrial'),
  ('finance', 'financial'),
  ('employment', 'unemployment'), // employ
  ('secure', 'security'),
  ('relation', 'relative'), // relate
  ('relation', 'relatively'), // relate
  ('relative', 'relatively'),
  ('object', 'objection'),
  ('object', 'objective'),
  ('objection', 'objective'), // object
  ('determine', 'determination'),
  ('maintain', 'maintenance'),
  ('represent', 'representative'),
  ('constitute', 'constitution'),
  ('independent', 'independence'), // depend
  ('dependent', 'independent'), // depend
  ('dependent', 'independence'), // depend
  ('significant', 'significance'), // signify
  ('contribute', 'contribution'),
  ('apparent', 'apparently'),
  ('accurate', 'accuracy'),
  ('tend', 'tendency'),
  ('associate', 'association'),
  ('comparison', 'comparative'), // compare
  ('concern', 'concerned'),
  ('regard', 'regarding'),
  ('consumer', 'consumption'), // consume
  ('consideration', 'considerable'), // consider
  ('require', 'requirement'),
  ('assist', 'assistance'),
  ('mere', 'merely'),
  ('consequence', 'consequently'),
  // 고등 어려움 앞 300개 — 우리말 뜻 글자가 같은 동음이의어
  ('justice', 'define'), // 정의(正義) / 정의(定義)하다
  ('regulation', 'define'), // 규정(규칙) / 규정하다
  ('formula', 'official'), // 공식 / 공식적인
  ('former', 'transfer'), // 이전(以前)의 / 이전(移轉)
  // 고등 어려움 301~500·칸 전체(2026-11-24 검토) — 뜻이 거의 같음
  ('concept', 'notion'), // 개념 / 관념
  ('vary', 'differ'), // 서로 다르다 / 다르다
  ('vary', 'diverse'), // 다양하다 / 다양한
  ('ensure', 'guarantee'), // 보장하다 / 보증하다
  ('aware', 'conscious'), // 인식하는 / 의식하는
  ('accurate', 'precise'), // 정확한 / 정밀한
  ('obtain', 'acquire'), // 획득하다 / 취득하다
  ('acquire', 'gain'), // 습득하다 / 얻다
  ('conservation', 'preservation'), // 보존 / 보전
  ('conservation', 'preserve'), // 보존 / 보존하다
  ('being', 'organism'), // 생명체 / 생물
  ('resident', 'inhabitant'), // 거주자 / 거주민
  ('nevertheless', 'nonetheless'), // 그런데도 / 그래도
  ('despite', 'nonetheless'), // ~에도 불구하고 / 그렇긴 하지만
  ('arise', 'emerge'), // 생기다 / (새로) 생겨나다
  ('reveal', 'emerge'), // 드러내다 / 모습을 드러내다
  ('object', 'oppose'), // (object to) ~에 반대하다 / 반대하다
  ('objection', 'oppose'), // 반대 / 반대하다
  ('contrary', 'oppose'), // 반대의 / 반대하다
  ('resist', 'oppose'), // 저항하다 / 대항하다
  ('vision', 'insight'), // 통찰력 / 통찰
  ('feature', 'characterize'), // (~을) 특징으로 하다 / 특징짓다
  ('convince', 'persuade'), // 납득시키다 / 설득하다
  ('accomplish', 'attain'), // 성취하다 / 달성하다
  ('appreciation', 'gratitude'), // 감사 / 고마움
  ('appreciate', 'gratitude'), // 고마워하다 / 고마움
  ('reveal', 'uncover'), // 밝히다 / 캐내다
  ('overcome', 'conquer'), // 극복하다 / (어려움을) 물리치다
  ('conquer', 'occupy'), // 정복하다 / 점령하다
  ('wealth', 'abundance'), // 풍부함 / 풍요
  ('wealth', 'abundant'), // 풍부함 / 풍부한
  ('admission', 'acknowledge'), // 인정 / 인정하다
  ('seek', 'pursue'), // 찾다 / 추구하다
  ('claim', 'insist'), // 주장하다 / (강하게) 주장하다
  ('maintain', 'insist'), // (계속) 주장하다 / (강하게) 주장하다
  ('demand', 'insist'), // 요구하다 / 강력히 요구하다
  ('demonstrate', 'prove'), // 입증하다 / 증명하다
  ('involved', 'engage'), // 참여하는 / (engage in) 참여하다
  ('retain', 'maintain'), // 보유하다 / 유지하다
  ('rely', 'dependent'), // 의지하다 / 의존하는
  ('tremendous', 'extraordinary'), // 굉장한 / 대단한
  ('extraordinary', 'remarkable'), // 비범한 / 놀라운
  ('approve', 'favor'), // (approve of) 찬성하다 / (in favor of) ~에 찬성하여
  ('commitment', 'devotion'), // 전념 / 헌신
  ('devotion', 'dedicate'), // 헌신 / 바치다
  ('excellence', 'distinction'), // 탁월함 / 뛰어남
  ('excellence', 'outstanding'), // 빼어남 / 뛰어난
  ('resemble', 'similarity'), // 닮다 / 닮은 점
  ('constitute', 'consist'), // 구성하다 / (consist of) ~로 구성되다
  ('composition', 'consist'), // 구성 / ~로 구성되다
  ('mutual', 'interact'), // 상호의 / 상호 작용하다
  ('advance', 'progressive'), // 진보 / 진보적인
  ('settle', 'resolve'), // (분쟁을) 매듭짓다 / 해결하다
  ('restrict', 'limitation'), // 제한하다 / 제약
  // 고등 어려움 301~500·칸 전체 — 어원이 같음(despair/desperate는 영어 접사 파생이 아니라 넣지 않음)
  ('commit', 'commitment'),
  ('demonstrate', 'demonstration'),
  ('preserve', 'preservation'),
  ('appreciate', 'appreciation'),
  ('abundant', 'abundance'),
  ('transform', 'transformation'),
  ('suspect', 'suspicion'),
  ('enthusiasm', 'enthusiastic'),
  ('certainty', 'uncertainty'),
  ('caution', 'cautious'),
  ('negotiate', 'negotiation'),
  ('persuade', 'persuasive'),
  ('overwhelm', 'overwhelming'),
  ('rely', 'reliable'),
  ('observation', 'observe'),
  ('involved', 'involve'),
  ('treatment', 'treat'),
  ('possession', 'possess'),
  ('reflect', 'reflection'),
  ('initial', 'initially'),
  ('favor', 'favorable'),
  ('favor', 'preference'), // 선호하다 / 선호(5단계 명사·동사 겸용어 점검)
  ('distinction', 'distinguish'), // distinct
  ('relation', 'relate'),
  ('relative', 'relate'),
  ('relatively', 'relate'),
  ('proposal', 'propose'),
  ('essential', 'essence'),
  ('access', 'accessible'),
  ('occupation', 'occupy'),
  ('intention', 'intend'),
  ('approval', 'approve'),
  ('emphasis', 'emphasize'),
  ('critical', 'criticize'), // critic
  ('interaction', 'interact'),
  ('characteristic', 'characterize'), // character
  ('consumption', 'consume'),
  ('consumer', 'consume'),
  ('distribution', 'distribute'),
  ('analysis', 'analyze'),
  ('aware', 'awareness'),
  ('sense', 'sensation'), // 감각 / 느낌·지각
  ('civil', 'civilization'), // civilize
  ('remark', 'remarkable'),
  ('affect', 'affection'),
  ('conservation', 'conservative'), // conserve
  ('current', 'currency'),
  // 고등 어려움 301~500·칸 전체 — 우리말 뜻 글자가 같은 동음이의어
  ('account', 'occupy'), // (account for) 차지하다 / (공간·시간을) 차지하다
  // 심화 쉬움 앞 300개(2026-11-25 검토) — 뜻이 거의 같음
  ('railroad', 'railway'), // (미국) 철도 / 철도
  ('baggage', 'luggage'), // 수하물 / 여행 짐
  ('bin', 'trash'), // 쓰레기통 / 쓰레기
  ('cabin', 'hut'), // 통나무집 / 오두막
  ('wizard', 'magician'), // 마법사 / 마술사
  ('nephew', 'niece'), // (남자) 조카 / 조카딸
  ('celebrity', 'entertainer'), // 유명인 / 연예인
  ('kettle', 'jug'), // 주전자 / 물병
  ('jar', 'jug'), // (유리) 병 / 큰 병
  ('mud', 'dirt'), // 진흙 / 흙
  // 심화 쉬움 앞 300개 — 어원이 같음
  ('dive', 'diving'),
  ('dive', 'diver'),
  ('diving', 'diver'),
  ('jog', 'jogging'),
  ('careless', 'carelessly'),
  ('mathematics', 'mathematician'),
  ('comedy', 'comedian'),
  ('spice', 'spicy'),
  ('baker', 'bakery'),
  // 심화 쉬움 앞 300개 — 우리말 뜻 글자가 같은 동음이의어
  ('sickness', 'jar'), // 병(질병) / (유리) 병
  // 심화 쉬움 묶음 4~6 — 뜻이 거의 같음
  ('port', 'harbor'), // 항구 / 항만
  ('previously', 'formerly'), // 이전에 / 예전에는
  ('fame', 'celebrity'), // 명성 / 유명세
  ('trunk', 'boot'), // (자동차) 트렁크
  ('rail', 'railway'), // 철도
  ('rail', 'railroad'), // 철도
  ('seller', 'dealer'), // 판매자 / 판매상
  ('seller', 'salesman'), // 판매자 / 판매원
  ('dealer', 'salesman'), // 판매상 / 판매원
  ('buyer', 'shopper'), // 구매자 / 물건 사는 사람
  ('grand', 'magnificent'), // 웅장한 / 장엄한
  ('district', 'province'), // 행정 구역
  ('bore', 'dull'), // 지루하게 하다 / 지루한
  // 심화 쉬움 묶음 4~6 — 어원이 같음
  ('employ', 'employer'),
  ('employ', 'employee'),
  ('employer', 'employee'),
  ('relief', 'relieved'),
  ('examination', 'examiner'),
  ('faith', 'faithful'),
  ('profit', 'profitable'),
  ('prompt', 'promptly'),
  ('indirect', 'indirectly'),
  ('mathematical', 'mathematics'),
  ('mathematical', 'mathematician'),
  ('taste', 'tasty'),
  ('blog', 'blogger'),
  ('backpack', 'backpacker'),
  ('detect', 'detective'),
  // 심화 쉬움 묶음 4~6 — 우리말 뜻 글자가 같은 동음이의어
  ('god', 'sour'), // 신 / (맛이) 신
  ('biography', 'electrical'), // (인물의) 전기 / 전기의
  // 심화 쉬움 마지막 검토가 더한 쌍 — 어원이 같음
  ('historic', 'prehistoric'),
  ('multiple', 'multiply'),
  ('gym', 'gymnastics'),
  ('electrical', 'electronics'),
  ('electrician', 'electronics'),
  ('export', 'import'),
  // 심화 쉬움 마지막 검토가 더한 쌍 — 뜻이 거의 같음·짝을 이루는 말
  ('stepmother', 'stepfather'),
  ('eruption', 'explode'), // (화산의) 폭발 / 폭발하다
  ('salesperson', 'seller'),
  ('salesperson', 'dealer'),
  // 심화 쉬움 묶음 7~9 검토가 더한 쌍 — 뜻이 거의 같음
  ('honestly', 'frankly'), // 솔직히
  ('polish', 'trim'), // 다듬다
  ('prompt', 'spark'), // 촉발하다
  ('narrator', 'storyteller'), // 이야기하는 사람
  ('cottage', 'hut'), // 시골의 작은 집 / 오두막
  ('cottage', 'cabin'), // 시골의 작은 집 / 통나무집
  ('dim', 'faint'), // 어둑한 / 희미한
  ('insane', 'madness'), // 미친 / 미친 짓
  ('enjoyment', 'delight'), // 기쁨 / 큰 기쁨
  ('enjoyable', 'delightful'), // 즐거운 / 아주 즐거운
  ('carriage', 'wagon'), // 마차 / 짐마차
  ('personally', 'privately'), // 개인적으로 / 사적으로
  ('openly', 'publicly'), // 드러내 놓고 / 공공연히
  // 심화 쉬움 묶음 7~9 검토가 더한 쌍 — 어원이 같음
  ('frozen', 'freezer'),
  ('lighter', 'lighting'),
  // 심화 쉬움 묶음 7~9 검토가 더한 쌍 — 우리말 뜻 글자가 같은 동음이의어
  ('pipe', 'coffin'), // 관
  ('bet', 'hook'), // 걸다
  // 심화 쉬움 묶음 7~9 — 뜻이 거의 같음
  ('instantly', 'promptly'), // 곧바로 / 즉시
  ('formally', 'officially'), // 정식으로 / 공식적으로
  ('stupid', 'foolish'), // 어리석은 / 바보 같은
  ('paradise', 'heaven'), // 지상 낙원 / 천국, 낙원
  ('nursery', 'preschool'), // 탁아소 / 어린이집
  ('loyal', 'faithful'), // 충성스러운 / 충실한
  ('consultant', 'adviser'), // 자문 위원 / 고문
  ('herd', 'flock'), // (짐승의) 떼 / (양·새의) 떼
  ('astonished', 'amazed'), // 깜짝 놀란 / 놀란
  ('costume', 'outfit'), // 의상 / 옷 한 벌
  ('elegant', 'graceful'), // 우아한 / 기품 있는
  ('cellar', 'basement'), // 지하 저장실 / 지하실
  ('litter', 'trash'), // (길에 버린) 쓰레기 / 쓰레기
  ('booklet', 'brochure'), // 소책자 / (안내용) 책자
  // 심화 쉬움 묶음 7~9 — 어원이 같음
  ('confess', 'confession'),
  ('delight', 'delighted'),
  ('delight', 'delightful'),
  ('delighted', 'delightful'),
  ('critic', 'criticism'),
  ('freezing', 'frozen'),
  ('freezing', 'freezer'),
  ('alcoholic', 'alcohol'),
  ('enjoyment', 'enjoyable'),
  ('incorrect', 'correction'),
  ('cruel', 'cruelty'),
  ('entertain', 'entertainer'),
  ('preferable', 'preferably'),
  ('twist', 'twisted'),
  ('decoration', 'decorative'),
  ('creator', 'creation'),
  ('cooperate', 'cooperative'),
  ('god', 'goddess'),
  ('edit', 'edition'),
  ('graph', 'graphics'),
  ('depart', 'departure'),
  ('hopeless', 'hopeful'),
  ('hopeful', 'hopefully'),
  ('hopeless', 'hopefully'),
  ('puzzle', 'puzzled'),
  ('evenly', 'uneven'),
  ('bomb', 'bombing'),
  ('eastward', 'eastern'),
  ('divorced', 'divorce'),
  ('magical', 'magician'),
  ('educate', 'educated'),
  ('entertain', 'entertaining'),
  ('entertainer', 'entertaining'),
  // 심화 쉬움 묶음 10~12 — 뜻이 거의 같음
  ('weird', 'odd'), // 기묘한 / 이상한
  ('talented', 'gifted'), // 재능이 뛰어난 / 재능 있는
  ('rubbish', 'trash'), // (영국) 쓰레기 / 쓰레기
  ('rubbish', 'litter'), // (영국) 쓰레기 / (길에 버린) 쓰레기
  ('bang', 'boom'), // 탕 하는 소리 / 쾅 하는 소리
  ('risky', 'unsafe'), // 위험한 / 안전하지 않은
  ('sparkling', 'shiny'), // 반짝반짝 빛나는 / 반짝이는
  ('lifelong', 'lifetime'), // 평생 동안의 / 평생
  ('rug', 'carpet'), // 깔개 / 양탄자
  ('buddy', 'mate'), // 단짝 / 친구
  ('humid', 'damp'), // 습한 / 눅눅한
  ('fright', 'scare'), // (갑작스러운) 공포 / 겁주다
  ('terrifying', 'scary'), // 몹시 무서운 / 무서운
  ('anxiously', 'nervously'), // 걱정스럽게 / 초조하게
  ('underwear', 'underpants'), // 속옷류 / 속옷
  ('leaflet', 'brochure'), // 전단 / 팸플릿
  ('unsure', 'doubtful'), // 확신하지 못하는 / 확신이 없는
  ('bump', 'bang'), // 부딪치다 / 세게 부딪치다
  ('ache', 'sore'), // 쑤시다 / 쑤시는
  ('tremble', 'shiver'), // 떨리다 / 부르르 떨다
  ('incredibly', 'unbelievable'), // 믿을 수 없을 만큼 / 믿을 수 없는
  ('saucepan', 'pot'), // 편수 냄비 / 냄비
  ('unkind', 'unfriendly'), // 불친절한 / 쌀쌀맞은
  ('clap', 'applause'), // 박수를 치다 / 박수
  ('stylish', 'fashionable'), // 맵시 있는 / 멋을 낸
  ('stylish', 'elegant'), // 맵시 있는 / 세련된
  ('salesperson', 'salesman'), // 판매 담당자 / 판매원
  ('eyelid', 'lid'), // (위아래) 눈꺼풀 / 눈꺼풀
  // 심화 쉬움 묶음 10~12 — 어원이 같음
  ('accidentally', 'accidental'),
  ('unexpectedly', 'expected'),
  ('educator', 'educate'),
  ('educator', 'educated'),
  ('muddy', 'mud'),
  ('gardener', 'gardening'),
  ('explorer', 'exploration'),
  ('cheerfully', 'cheerful'),
  ('amazement', 'amazed'),
  ('sticky', 'sticker'),
  ('racist', 'racial'),
  ('luxurious', 'luxury'),
  ('rebuild', 'builder'),
  ('thickly', 'thickness'),
  ('trainer', 'trainee'),
  ('infect', 'infected'),
  ('scare', 'scary'),
  ('unofficial', 'officially'),
  ('bomber', 'bomb'),
  ('bomber', 'bombing'),
  ('ache', 'backache'),
  ('ache', 'earache'),
  ('relaxing', 'relaxation'),
  ('curl', 'curly'),
  ('programmer', 'programming'),
  ('tighten', 'tightly'),
  ('indoors', 'outdoors'),
  ('blindly', 'blindness'),
  ('unsure', 'surely'),
  ('soak', 'soaked'),
  ('starve', 'starving'),
  ('bump', 'bumper'),
  ('coward', 'cowardly'),
  ('browse', 'browser'),
  ('sparkling', 'sparkle'),
  ('sparkle', 'spark'),
  ('sparkling', 'spark'),
  ('stubborn', 'stubbornly'),
  ('boxer', 'boxing'),
  ('craftsman', 'craft'),
  ('bathe', 'sunbathe'),
  ('electrician', 'electrical'),
  ('cruelly', 'cruel'),
  ('cruelly', 'cruelty'),
  ('amazingly', 'amazed'),
  ('amazingly', 'amazement'),
  ('endlessly', 'endless'),
  ('unfriendly', 'friendly'),
  ('unfriendly', 'friendliness'),
  ('friendliness', 'friendly'),
  ('decorate', 'decoration'),
  ('decorate', 'decorative'),
  ('lighten', 'lightly'),
  ('messy', 'mess'),
  ('donate', 'donation'),
  ('landlady', 'landlord'),
  ('creatively', 'creation'),
  ('creatively', 'creator'),
  // 심화 중간 묶음 1~3 — 뜻이 거의 같음
  ('assessment', 'evaluation'), // (실력·상황의) 평가 / 평가
  ('dated', 'old-fashioned'), // 시대에 뒤떨어진 / 구식의
  ('adequate', 'sufficiently'), // 충분한 / 충분히
  ('essentially', 'fundamental'), // 본질적으로 / 근본적인
  ('constant', 'consistent'), // 일정한 / 한결같은 — 생김새도 비슷함(검토 2026-11-26)
  ('opposition', 'resistance'), // 반대 / 반발
  ('adequate', 'satisfactory'), // 그럭저럭 괜찮은 / (기준에) 맞는·만족스러운
  ('overall', 'altogether'), // 전반적으로 / 대체로·모두 합해서
  // 심화 중간 묶음 1~3 — 어원이 같음
  ('skateboard', 'skateboarder'),
  ('division', 'divided'),
  ('extension', 'extensive'),
  ('excess', 'exceed'),
  ('adopted', 'adoption'),
  ('manufacturing', 'manufacture'),
  ('identify', 'identification'),
  ('variation', 'varied'),
  ('ultimately', 'ultimate'),
  ('prior', 'priority'),
  ('will', 'willing'),
  ('provided', 'provision'),
  // 심화 중간 묶음 1~3 — 우리말 뜻 글자가 같은 동음이의어
  ('unpack', 'untie'), // (짐을) 풀다 / (매듭·끈을) 풀다
  // 심화 중간 묶음 4~6 — 뜻이 거의 같음
  ('evaluate', 'assess'), // 평가하다·감정하다 / 산정하다·가늠하다
  ('assess', 'evaluation'), // 산정하다 / (가치) 평가
  ('geographic', 'geographical'), // 지리상의 / 지리적인
  ('continuously', 'continually'), // 연속해서 / 계속해서
  ('insufficient', 'inadequate'), // 부족한 / 불충분한
  ('alter', 'modification'), // 고치다·바꾸다 / 변경
  ('adequately', 'sufficiently'), // 적절히 / 충분히
  ('competence', 'capability'), // 유능함·적격 / 능력
  // 아래는 2026-11-26 검토가 더한 쌍
  ('faculty', 'capability'), // (타고난) 능력 / 능력
  ('evolution', 'advancement'), // (점진적) 발전 / 발전
  ('grief', 'sorrow'), // 슬픔
  ('refusal', 'rejection'), // 거절
  ('lasting', 'persistent'), // 지속적인 / 지속되는
  ('hazardous', 'toxic'), // 유해한 / 유독한
  ('humble', 'modest'), // 겸허한 / 겸손한
  ('actual', 'genuine'), // 실제의 / 진짜의
  ('crucial', 'vital'),
  ('abandoned', 'neglect'), // 방치된 / 방치
  ('eligible', 'competence'), // 적격의 / 적격
  ('regulate', 'restriction'),
  ('counseling', 'consult'),
  ('constant', 'continually'), // 끊임없는 / 끊임없이
  ('thoroughly', 'utterly'),
  ('navigation', 'voyage'),
  // 심화 중간 묶음 4~6 — 우리말 뜻 글자가 같은 동음이의어(검토 2026-11-26)
  ('acid', 'mount'), // 산(酸) / 산
  ('tribe', 'insufficient'), // 부족(部族) / 부족한
  // 심화 중간 묶음 4~6 — 어원이 같음
  ('glory', 'glorious'),
  ('lawful', 'legally'),
  ('evaluate', 'assessment'),
  ('excessive', 'excess'),
  ('excessive', 'exceed'),
  ('manufacturer', 'manufacture'),
  ('manufacturer', 'manufacturing'),
  ('separately', 'separation'),
  ('inspector', 'inspection'),
  ('evaluate', 'evaluation'),
  ('assess', 'assessment'),
  ('assure', 'assurance'),
  ('residential', 'residence'),
  ('database', 'data'),
  ('inadequate', 'adequate'),
  ('illustrate', 'illustration'),
  ('engagement', 'engaged'),
  ('adequately', 'adequate'),
  ('scholar', 'scholarship'),
  ('perceive', 'perception'),
  ('interpret', 'interpretation'),
  ('ignorant', 'ignorance'),
  ('convert', 'conversion'),
  ('govern', 'governor'),
  ('competence', 'competent'),
  ('consensus', 'consent'),
  ('exclude', 'exclusive'),
  ('secondly', 'secondary'),
  // 심화 중간 묶음 7~9 — 뜻이 거의 같음
  ('sincere', 'genuine'), // 진실한 / 진짜의
  ('crucial', 'decisive'), // 매우 중요한 / 결정적인
  ('respectable', 'honorable'), // 존경받을 만한 / 존경할 만한
  ('tomb', 'grave'), // 묘소 / 무덤
  ('viewpoint', 'perspective'), // 견해 / 관점
  ('forbidden', 'prohibit'), // 금지된 / 금지하다
  ('query', 'inquiry'), // 질문 / 문의
  ('anticipation', 'expectation'), // 고대 / 기대
  ('passionate', 'keen'), // 열정적인 / 열렬한
  ('poisonous', 'toxic'), // 독이 있는 / 유독한
  // 심화 중간 묶음 7~9 — 어원이 같음
  ('qualification', 'qualify'),
  ('willingness', 'willing'),
  ('vacant', 'vacancy'),
  ('prescribe', 'prescription'),
  ('misery', 'miserable'),
  ('innovative', 'innovation'),
  ('prohibit', 'prohibition'),
  ('terror', 'terrorism'),
  ('preventive', 'prevention'),
  ('therapist', 'therapy'),
  ('unite', 'united'),
  ('philosopher', 'philosophical'),
  ('investor', 'investment'),
  ('investigator', 'investigate'),
  ('offender', 'offense'),
  ('compensate', 'compensation'),
  ('anticipate', 'anticipation'),
  ('dread', 'dreadful'),
  ('tenderness', 'tender'),
  ('technically', 'technical'),
  ('literal', 'literally'),
  ('trailer', 'trail'),
  ('continual', 'continually'),
  ('continual', 'continuously'),
  ('unsatisfactory', 'satisfactory'),
  ('opponent', 'opposition'),
  ('unwilling', 'willing'),
  ('unwilling', 'willingness'),
  ('threaten', 'threatening'),
  ('willingly', 'willing'),
  ('willingly', 'willingness'),
  ('willingly', 'unwilling'),
  ('obedient', 'obedience'),
  ('radically', 'radical'),
  ('assemble', 'assembly'),
  ('improperly', 'improper'),
  ('persist', 'persistent'),
  ('spectacular', 'spectator'),
  ('interpreter', 'interpret'),
  ('interpreter', 'interpretation'),
  ('astonishing', 'astonishment'),
  // 심화 중간 묶음 7~9 — 뜻이 거의 같음(검토 2026-11-26)
  ('adequately', 'appropriately'), // 적절히 / 적절하게
  ('strictly', 'technically'), // 엄밀히 / 엄밀히 따지면
  ('anticipate', 'expectation'), // 예상하다·기대하다 / 기대·예상
  ('hard-working', 'diligence'), // 근면한 / 근면
  ('sincere', 'diligence'), // 성실한 / 성실
  ('forbidden', 'prohibition'), // 금지된 / 금지
  ('absurd', 'unreasonable'),
  ('misery', 'suffering'),
  ('grim', 'gloomy'), // 암울한 / 우울한
  ('striking', 'noticeable'), // 두드러진 / 눈에 띄는
  ('certificate', 'qualification'), // 증명서·수료증 / 자격증
  ('inadequate', 'improperly'), // 부적절한 / 부적절하게
  ('strip', 'peel'), // 벗기다 / 껍질을 벗기다
  ('particle', 'microscopic'), // 극히 작은 조각 / 극히 작은
  ('briefly', 'straightforward'), // 간단히 / 간단한
  ('nuisance', 'troublesome'), // 성가신 사람 / 성가신
  ('dreadful', 'terribly'), // 끔찍한 / 끔찍하게
  ('addiction', 'alcoholism'), // 중독 / 알코올 중독
  ('eligible', 'qualification'), // 자격이 있는 / 자격
  ('recommendation', 'nomination'), // 추천 / 후보 추천
  ('nerve', 'tense'), // (nerves) 긴장 / 긴장한
  ('fundamental', 'radically'), // 근본적인 / 근본적으로
  ('opening', 'slot'), // 구멍 / 가느다란 구멍
  ('oath', 'swear'), // 맹세 / 맹세하다
  ('breeding', 'reproduce'), // 번식 / 번식하다
  ('interfere', 'interruption'), // 방해하다 / 방해
  ('adjustment', 'revise'), // 수정 / 수정하다
  ('blast', 'explosive'), // 폭발 / 폭발물·폭발성의
  // 심화 중간 묶음 7~9 — 어원이 같음(검토 2026-11-26)
  ('mortal', 'immortal'),
  ('imply', 'implication'),
  ('western', 'westward'),
  // 심화 중간 묶음 7~9 — 우리말 뜻 글자가 같은 동음이의어(검토 2026-11-26)
  ('transition', 'fulfill'), // 이행(移行) / 이행하다(履行)
  ('decay', 'corrupt'), // 부패 / 부패한
  ('numerical', 'disgrace'), // 수치상의 / 수치(羞恥)
  // 심화 중간 묶음 10~13 — 뜻이 거의 같음
  ('knowingly', 'intentionally'),
  ('laborer', 'workman'),
  ('irrational', 'unreasonable'),
  ('hasty', 'rash'),
  ('suitably', 'appropriately'),
  ('suitably', 'adequately'),
  ('annoyance', 'irritation'),
  ('humiliation', 'embarrassment'),
  ('regain', 'retrieve'),
  ('bizarre', 'peculiar'),
  ('wrongly', 'improperly'),
  ('fabulous', 'spectacular'),
  ('fabulous', 'terrific'),
  ('skillful', 'skilled'),
  ('globally', 'internationally'),
  ('widen', 'broaden'),
  ('pharmacist', 'chemist'),
  ('predicament', 'dilemma'),
  ('unjustly', 'wrongly'),
  ('politeness', 'courtesy'),
  ('softness', 'tenderness'),
  ('refute', 'contradict'),
  ('crossroads', 'intersection'),
  ('grieve', 'mourn'),
  ('leisurely', 'easygoing'),
  // 심화 중간 묶음 10~13 — 어원이 같음
  ('improbable', 'probable'),
  ('genuinely', 'genuine'),
  ('optimism', 'optimist'),
  ('densely', 'dense'),
  ('tolerant', 'tolerate'),
  ('dissatisfied', 'dissatisfaction'),
  ('merge', 'merger'),
  ('revive', 'revival'),
  ('legendary', 'legend'),
  ('generously', 'generosity'),
  ('weaken', 'weakly'),
  ('irritated', 'irritation'),
  ('irritated', 'irritating'),
  ('irritating', 'irritation'),
  ('prosper', 'prosperous'),
  ('broaden', 'broadly'),
  ('thrill', 'thrilled'),
  ('thrill', 'thrilling'),
  ('thrilled', 'thrilling'),
  ('prestigious', 'prestige'),
  ('psychologically', 'psychology'),
  ('navigate', 'navigation'),
  ('tenderly', 'tender'),
  ('tenderly', 'tenderness'),
  ('passionately', 'passionate'),
  ('addicted', 'addiction'),
  ('impulsive', 'impulse'),
  ('verbally', 'verbal'),
  ('humiliating', 'humiliation'),
  ('astronomer', 'astronomy'),
  ('hospitable', 'hospitality'),
  ('impatiently', 'patiently'),
  ('amuse', 'amusing'),
  ('grieve', 'grief'),
  ('specialize', 'specialty'),
  // 심화 중간 칸 마지막 검토 — 뜻이 같거나 어원이 같은 쌍(2026-11-26)
  ('gross', 'disgusting'),
  ('tender', 'affectionate'),
  ('evolve', 'evolution'),
  ('evolve', 'advancement'),
  ('tense', 'stressful'),
  ('nerve', 'stressful'),
  ('courageous', 'bravery'),
  ('discourage', 'courageous'),
  ('depressing', 'gloomy'),
  ('voyage', 'navigate'),
  ('lame', 'limp'),
  ('rash', 'carelessness'),
  ('gene', 'genetically'),
  ('liberal', 'liberation'),
  ('liberal', 'generosity'),
  ('liberal', 'generously'),
  ('generosity', 'tolerant'),
  ('dependable', 'trustworthy'),
  ('unrealistic', 'impractical'),
  ('disappearance', 'vanish'),
  ('glare', 'stunning'),
  ('stunning', 'brilliantly'),
  ('glare', 'brilliantly'),
  ('bothered', 'irritated'),
  ('bothered', 'irritating'),
  ('bothered', 'irritation'),
  ('dread', 'terrified'),
  ('terror', 'terrified'),
  ('terribly', 'terrified'),
  ('terrified', 'terrific'),
  ('terribly', 'terrific'),
  ('optimism', 'rosy'),
  ('optimist', 'rosy'),
  ('timing', 'timely'),
  ('unsatisfactory', 'dissatisfied'),
  ('satisfactory', 'dissatisfied'),
  ('satisfactory', 'dissatisfaction'),
  ('unsatisfactory', 'dissatisfaction'),
  ('sufficiently', 'insufficient'),
  ('inadequate', 'adequately'),
  ('inadequate', 'unsuitable'),
  ('improperly', 'unsuitable'),
  ('suitably', 'unsuitable'),
  ('accurately', 'inaccurate'),
  ('conveniently', 'inconvenient'),
  ('discomfort', 'inconvenient'),
  ('discomfort', 'comfortably'),
  ('ease', 'comfortably'),
  ('effectiveness', 'ineffective'),
  ('acceptance', 'unacceptable'),
  ('resistance', 'irresistible'),
  ('hearing', 'unheard'),
  ('impolite', 'politeness'),
  ('unhelpful', 'helpless'),
  ('understandable', 'misunderstanding'),
  ('separation', 'inseparable'),
  ('separately', 'inseparable'),
  ('specially', 'specialty'),
  ('specially', 'specialize'),
  ('alternate', 'alternatively'),
  ('economics', 'economical'),
  ('publication', 'publicity'),
  ('formation', 'format'),
  ('jury', 'juror'),
  ('considerably', 'reconsider'),
  ('leading', 'misleading'),
  ('unpack', 'packing'),
  ('packing', 'packed'),
  ('unpack', 'packed'),
  ('disgrace', 'shameful'),
  ('noticeable', 'visibly'),
  ('graphic', 'vividly'),
  ('keen', 'passionately'),
  ('unreasonable', 'unjustly'),
  ('informal', 'casually'),
  ('deduction', 'subtract'),
  ('warmth', 'hearty'),
  ('finely', 'terrific'),
  ('lessen', 'shrink'),
  ('idle', 'leisurely'),
  ('annoyance', 'nuisance'),
  ('annoyance', 'troublesome'),
  ('improved', 'upgrade'),
  ('consistent', 'coherence'),
  ('genuine', 'dearly'),
  ('genuinely', 'dearly'),
  ('accurately', 'correctness'),
  ('monk', 'monastery'),
  ('sympathetic', 'compassion'),
  ('affectionate', 'tenderly'),
  ('affectionate', 'tenderness'),
  ('fondness', 'affectionate'),
  ('bearing', 'unbearable'),
  ('universal', 'globally'),
  // 심화 어려움 묶음 1~3 — 뜻이 거의 같음
  ('reorganize', 'rearrange'),
  ('astonish', 'amaze'),
  // 심화 어려움 묶음 1~3 — 어원이 같음
  ('unease', 'uneasily'),
  ('unimaginable', 'unimaginably'),
  ('legislative', 'legislature'),
  ('executive', 'execution'),
  ('corresponding', 'correspondence'),
  // 심화 어려움 묶음 1~3 — 검토가 더한 쌍(2026-11-26)
  ('sociable', 'socialize'),
  ('misunderstand', 'understanding'),
  ('lawmaker', 'legislature'),
  ('lawmaker', 'legislative'),
  ('supervision', 'superintendent'),
  ('administrative', 'supervision'),
  ('county', 'administrative'),
  ('governmental', 'administrative'),
  ('partial', 'segment'),
  ('segment', 'sector'),
  ('innocently', 'spite'),
  ('unmistakably', 'definite'),
  ('marked', 'definite'),
  ('disorganized', 'well-organized'),
  ('disorganized', 'reorganize'),
  ('irritate', 'bad-tempered'),
  ('preoccupy', 'possessed'),
  ('preoccupy', 'intent'),
  ('circuit', 'circular'),
  ('divine', 'sacred'),
  ('uncomfortably', 'unease'),
  ('uncomfortably', 'uneasily'),
  ('unconcerned', 'uninterested'),
  ('carefree', 'unconcerned'),
  ('stun', 'astonish'),
  ('stun', 'amaze'),
  ('hugely', 'fantastically'),
  ('hugely', 'significantly'),
  ('commerce', 'merchant'),
  ('unbeatable', 'unstoppable'),
  ('indescribable', 'unimaginable'),
  ('irresistibly', 'invitingly'),
  ('inflate', 'magnify'),
  ('outing', 'getaway'),
  // 심화 어려움 묶음 4~6 — 뜻이 거의 같음
  ('haven', 'refuge'),
  ('coalition', 'alliance'),
  ('mighty', 'potent'),
  ('petty', 'trivial'),
  ('needless', 'pointless'),
  ('strive', 'endeavor'),
  ('awe', 'reverence'),
  // 심화 어려움 묶음 4~6 — 어원이 같음
  ('withdraw', 'withdrawal'),
  ('exclusion', 'exclusively'),
  ('specify', 'specifically'),
  ('deficiency', 'deficit'),
  ('merchandise', 'merchant'),
  ('deliberate', 'deliberately'),
  ('testimony', 'testify'),
  ('inflammation', 'inflammatory'),
  ('transmit', 'transmission'),
  ('correspondent', 'correspondence'),
  ('correspondent', 'corresponding'),
  ('devote', 'devoted'),
  ('devote', 'dedication'),
  ('devoted', 'dedication'),
  ('pastor', 'pastoral'),
  ('bankruptcy', 'bankrupt'),
  ('respiratory', 'respiration'),
  ('stimulation', 'stimulate'),
  ('utilize', 'utility'),
  ('conceive', 'conception'),
  ('ally', 'alliance'),
  ('contradiction', 'contradictory'),
  ('certify', 'certification'),
  ('infringement', 'violate'),
  ('adverse', 'adversely'),
  ('vigorous', 'vigorously'),
  ('ambiguous', 'ambiguity'),
  ('haste', 'hastily'),
  ('authorize', 'unauthorized'),
  ('authorize', 'authoritative'),
  ('vain', 'vanity'),
  ('patriotic', 'patriotism'),
  ('inference', 'infer'),
  ('bureau', 'bureaucracy'),
  ('trait', 'attribute'),
  ('impartial', 'partial'),
  ('turbulent', 'turbulence'),
  ('morality', 'morally'),
  ('sanitary', 'sanitation'),
  // 심화 어려움 묶음 4~6 — 검토가 더한 쌍(뜻·어원이 같거나 우리말 뜻 글자가 붙어 보임, 2026-11-26)
  ('colon', 'semicolon'),
  ('transmission', 'plague'),
  ('plague', 'pandemic'),
  ('deed', 'warranty'),
  ('certification', 'transcript'),
  ('certify', 'transcript'),
  ('span', 'long-term'),
  ('respiration', 'scuba'),
  ('recollection', 'catchy'),
  ('coincidence', 'overhear'),
  ('coincidence', 'simultaneous'),
  ('marked', 'distinctly'),
  ('minimize', 'miniature'),
  ('micro', 'miniature'),
  ('micro', 'microscopy'),
  ('availability', 'utilize'),
  ('landslide', 'triumph'),
  ('clarify', 'unclearly'),
  ('conceive', 'unimaginable'),
  ('conceive', 'unimaginably'),
  ('redo', 'resume'),
  ('redo', 'reprint'),
  ('upright', 'erect'),
  ('politically', 'statesman'),
  ('invariably', 'exceptionally'),
  ('merchandise', 'commerce'),
  ('fiscal', 'audit'),
  ('suppress', 'oppression'),
  ('oppression', 'tyranny'),
  ('deficiency', 'shortness'),
  ('spur', 'stimulate'),
  ('prospect', 'projection'),
  ('transient', 'transitional'),
  ('nobility', 'royalty'),
  ('spite', 'piety'),
  ('sexual', 'transcript'),
  ('citizenship', 'patriotic'),
  ('counter', 'compute'),
  ('diversion', 'transitional'),
  // 심화 어려움 묶음 7~9 — 뜻이 거의 같거나 어원·우리말 글자가 붙어 보임(묶음 7)
  ('endurance', 'enduring'),
  ('everlasting', 'eternity'),
  ('coincide', 'coincidence'),
  ('coincide', 'correspondence'),
  ('vigor', 'vigorous'),
  ('vigor', 'vigorously'),
  ('harness', 'utilize'),
  ('eloquence', 'eloquent'),
  ('humane', 'pavement'),
  ('humane', 'acknowledgment'),
  ('classify', 'classification'),
  ('duplication', 'redundant'),
  ('supervise', 'supervision'),
  ('evacuation', 'evacuate'),
  ('evacuation', 'refuge'),
  ('originate', 'originality'),
  ('aristocracy', 'nobility'),
  ('rite', 'consciousness'),
  ('tread', 'tiptoe'),
  ('admittedly', 'acknowledgment'),
  ('accusation', 'condemn'),
  ('recollect', 'recollection'),
  ('predictive', 'projection'),
  ('handicap', 'adverse'),
  ('holocaust', 'slaughter'),
  ('doom', 'misfortune'),
  ('overly', 'oversize'),
  ('anguish', 'agony'),
  ('excursion', 'outing'),
  ('redundant', 'needless'),
  ('devastating', 'disastrous'),
  ('narrowly', 'scarcely'),
  ('catastrophe', 'disastrous'),
  ('coincide', 'overlap'),
  // 심화 어려움 묶음 7~9 — 뜻이 거의 같거나 어원·우리말 글자가 붙어 보임(묶음 8)
  ('benevolence', 'benevolent'),
  ('burglary', 'burglar'),
  ('tyrant', 'tyranny'),
  ('orator', 'eloquence'),
  ('fascination', 'fascinate'),
  ('exaggeration', 'magnify'),
  ('concede', 'acknowledgment'),
  ('despise', 'contempt'),
  ('witty', 'wit'),
  ('attainable', 'attainment'),
  ('stride', 'tread'),
  ('predictor', 'projection'),
  ('predictor', 'predictive'),
  ('nobleman', 'nobility'),
  ('nobleman', 'aristocracy'),
  ('attractiveness', 'unattractive'),
  ('weave', 'compile'),
  ('extraordinarily', 'hugely'),
  ('extraordinarily', 'exceptionally'),
  ('peg', 'stake'),
  ('perseverance', 'persistence'),
  ('distraction', 'diversion'),
  ('gleam', 'twinkle'),
  ('foresee', 'unforeseen'),
  // 심화 어려움 묶음 7~9 — 뜻이 거의 같거나 어원·우리말 글자가 붙어 보임(묶음 9)
  ('legislator', 'legislative'),
  ('legislator', 'legislature'),
  ('legislator', 'legislate'),
  ('legislate', 'legislative'),
  ('legislate', 'legislature'),
  ('legislator', 'lawmaker'),
  ('tramp', 'tread'),
  ('standby', 'await'),
  ('aggressively', 'assault'),
  ('adversity', 'adverse'),
  ('adversity', 'adversely'),
  ('delicately', 'delicacy'),
  ('piracy', 'duplication'),
  ('tremor', 'quake'),
  ('tremor', 'vibration'),
  ('retard', 'handicap'),
  ('cripple', 'handicap'),
  ('burdensome', 'strain'),
  ('aspire', 'aspiration'),
  ('figurative', 'analogy'),
  ('eternally', 'eternity'),
  ('eternally', 'everlasting'),
  ('circuitry', 'circuit'),
  ('stimulant', 'stimulation'),
  ('stimulant', 'stimulate'),
  ('subconscious', 'consciousness'),
  ('pebble', 'treaty'),
  ('ruinous', 'doom'),
  ('ruinous', 'adverse'),
  ('ruinous', 'devastating'),
  ('replica', 'miniature'),
  ('replica', 'duplication'),
  ('invariable', 'invariably'),
  ('compress', 'compression'),
  ('adorn', 'ornament'),
  ('scramble', 'hastily'),
  ('soothe', 'console'),
  ('ponder', 'muse'),
  ('glee', 'ecstasy'),
  ('deduce', 'infer'),
  ('forcefully', 'vigorously'),
  ('forcefully', 'emphatically'),
  ('flutter', 'flap'),
  // 심화 어려움 묶음 7~9 — 검토가 더한 쌍(2026-11-26)
  ('rite', 'ritual'),
  ('endurance', 'perseverance'),
  ('intrusion', 'burglary'),
  ('entrepreneur', 'corporation'),
  ('arouse', 'pose'),
  ('concede', 'admittedly'),
  ('supervise', 'superintendent'),
  ('complicate', 'complexity'),
  ('disorderly', 'orderly'),
  ('orator', 'eloquent'),
  // 심화 어려움 — 19개를 빼며 중간 칸에서 옮겨 온 말과의 쌍(2026-11-26)
  ('zoom', 'magnify'),
  ('magnify', 'exaggerate'),
  ('attainable', 'achievable'),
  ('affectionately', 'fondly'),
  ('affectionately', 'lovingly'),
  // 심화 어려움 묶음 10~12 — 뜻이 같은 쌍·어원이 같은 쌍·뜻 글자가 붙어 보이는 쌍(2026-11-27)
  ('bustle', 'bustling'),
  ('categorization', 'categorize'),
  ('classification', 'categorization'),
  ('classify', 'categorize'),
  ('violate', 'infringe'),
  ('infringe', 'infringement'),
  ('innate', 'inborn'),
  ('mutter', 'murmur'),
  ('misconception', 'misunderstand'),
  ('misconception', 'conception'),
  ('proponent', 'partisan'),
  ('detach', 'detachment'),
  ('polio', 'paralysis'),
  ('nourish', 'nourishment'),
  ('modernize', 'modernization'),
  ('intrude', 'intrusion'),
  ('intrude', 'intruder'),
  ('vibrate', 'vibration'),
  ('oppress', 'oppression'),
  ('repress', 'repression'),
  ('repress', 'oppress'),
  ('ecologically', 'ecology'),
  ('ecstatic', 'ecstasy'),
  ('pave', 'pavement'),
  ('indulge', 'indulgent'),
  ('overturn', 'overthrow'),
  ('enthusiast', 'enthusiastically'),
  ('amplify', 'amplifier'),
  ('glorify', 'exalt'),
  ('reunification', 'unify'),
  ('repress', 'suppress'),
  ('solidity', 'firmness'),
  ('sneer', 'taunt'),
  ('overestimate', 'underestimate'),
  ('startle', 'astonish'),
  ('glint', 'gleam'),
  ('stagger', 'stumble'),
  ('droop', 'sag'),
  ('trample', 'tread'),
  ('yearn', 'aspire'),
  ('selfless', 'unselfish'),
  ('immerse', 'preoccupy'),
  ('contaminate', 'pollutant'),
  ('inscribe', 'inscription'),
  ('paralyze', 'paralysis'),
  ('polio', 'paralyze'),
  ('hyperbole', 'exaggerate'),
  ('hyperbole', 'exaggeration'),
  ('microorganism', 'microbe'),
  ('impressionist', 'impressionism'),
  ('ecologist', 'ecology'),
  ('ecologically', 'ecologist'),
  ('mutter', 'mumble'),
  ('murmur', 'mumble'),
  ('mutable', 'mutability'),
  ('outdo', 'outshine'),
  ('ecstatic', 'overjoyed'),
  ('ecstatic', 'exultant'),
  ('overjoyed', 'exultant'),
  ('tiresome', 'wearisome'),
  ('familiarize', 'accustom'),
  ('overshadow', 'outdo'),
  ('ravage', 'devastating'),
  ('indignity', 'humiliate'),
  ('enthusiast', 'freak'),
  ('exclaim', 'bellow'),
  ('uncharacteristic', 'atypical'),
  ('penniless', 'needy'),
  ('tiresome', 'bothersome'),
  ('bothersome', 'burdensome'),
  ('lark', 'skylark'),
  ('timeless', 'ageless'),
  ('transitive', 'intransitive'),
  ('obsessive', 'obsess'),
  ('obsess', 'preoccupy'),
  ('burgle', 'burglary'),
  ('burgle', 'burglar'),
  ('shoplifting', 'shoplifter'),
  ('shoplift', 'shoplifter'),
  ('reunification', 'reunify'),
  ('unify', 'reunify'),
  ('bewilderment', 'bewilder'),
  ('bewilder', 'mystify'),
  ('stun', 'bewilderment'),
  ('stun', 'bewilder'),
  ('personification', 'personify'),
  ('humanize', 'dehumanize'),
  ('industrialize', 'preindustrial'),
  ('pawnbroker', 'pawnshop'),
  ('newscaster', 'anchorperson'),
  ('newscaster', 'broadcaster'),
  ('anchorperson', 'broadcaster'),
  ('devastate', 'devastating'),
  ('ravage', 'devastate'),
  ('dispensable', 'indispensable'),
  ('impermanent', 'permanence'),
  ('impermanent', 'transient'),
  ('mutable', 'impermanent'),
  ('unworldly', 'worldly'),
  ('enthusiast', 'unenthusiastic'),
  ('enthusiastically', 'unenthusiastic'),
  ('mortify', 'humiliate'),
  ('aborigine', 'aboriginal'),
  ('workaholic', 'addict'),
  ('unthinkably', 'unimaginably'),
  ('outshine', 'overshadow'),
  ('outdo', 'outdistance'),
  ('overemphasize', 'exaggerate'),
  ('agonize', 'agony'),
  ('citywide', 'countrywide'),
  ('idolize', 'adore'),
  ('shoplifting', 'shoplift'),
  ('feverishly', 'frantically'),
  ('beautify', 'adorn'),
  ('indignity', 'dignity'),
  ('dignify', 'dignity'),
  ('shoplifter', 'burglar'),
  ('startle', 'horrify'),
  ('daze', 'stun'),
  ('outdo', 'excel'),
  ('unify', 'integrate'),
  // 심화 어려움 칸 마지막 검토 — 옮겨 온 말과의 쌍·뜻 글자가 붙어 보이는 쌍·파생어(2026-11-27)
  ('exaggerate', 'exaggeration'),
  ('lovingly', 'fondly'),
  ('intruder', 'intrusion'),
  ('fluency', 'eloquent'),
  ('fluency', 'eloquence'),
  ('achievable', 'attainment'),
  ('nutritious', 'nourishment'),
  ('nutritious', 'nourish'),
  ('bum', 'tramp'),
  ('overtake', 'outdistance'),
  ('meditate', 'ponder'),
  ('meditate', 'muse'),
  ('nervousness', 'unease'),
  ('tumble', 'stumble'),
  ('dishonesty', 'truthfulness'),
  ('sympathize', 'compassionate'),
  ('elegantly', 'gracefulness'),
  ('innocently', 'unworldly'),
  ('calmness', 'serene'),
  ('startle', 'amaze'),
  ('barren', 'desolation'),
  ('gall', 'cheeky'),
  ('emphatically', 'firmness'),
  ('rebellious', 'defy'),
  ('cease', 'disrupt'),
  ('turbulence', 'disrupt'),
  ('suspiciously', 'mistrustful'),
  ('up-to-date', 'modernize'),
  ('dazzle', 'ecstatic'),
  ('ecstasy', 'overjoyed'),
  ('ecstasy', 'exultant'),
  ('glee', 'overjoyed'),
  ('glee', 'exultant'),
  ('queer', 'abnormally'),
  ('mighty', 'forcefully'),
  ('mighty', 'emphatically'),
  ('severely', 'cripple'),
  ('deed', 'piracy'),
  ('erect', 'invoke'),
  ('extraordinarily', 'chaotic'),
  ('extraordinarily', 'incense'),
  ('extraordinarily', 'ruinous'),
  ('administrative', 'supervise'),
  ('editorial', 'compile'),
  ('deforestation', 'forestry'),
  ('humane', 'humanize'),
  ('tramp', 'trample'),
  // 심화 어려움 — 22개를 빼며 중간 칸에서 옮겨 온 말과의 쌍(2026-11-27)
  ('prick', 'stab'), // 콕 찌르다 / 찌르다
  ('picky', 'tricky'), // 까다롭게 고르는 / 까다로운
  // 심화 6단계 검토 — 칸을 옮긴 말과 새 칸 나머지의 쌍(2026-11-27)
  ('foolishly', 'unwise'),
  ('foolishly', 'dumb'),
  ('foolishly', 'idiot'),
  ('tiring', 'tiredness'),
  ('tiring', 'exhaust'),
  ('adorable', 'darling'),
  ('checkout', 'calculation'),
  ('undress', 'strip'),
  ('sunbeam', 'beam'),
  ('presenter', 'publication'),
  ('silverware', 'implement'),
  ('tasteless', 'elegance'),
  ('gangster', 'tissue'),
  ('stab', 'wound'),
  ('booking', 'overbook'),
  ('unfairly', 'impartial'),
  ('animate', 'inanimate'),
  ('generalize', 'generalization'),
  ('disconnect', 'detachment'),
  ('inject', 'intravenous'),
  ('lovingly', 'beloved'),
  ('fondly', 'devoted'),
  ('lovingly', 'devoted'),
  ('affectionately', 'devoted'),
  ('exaggerate', 'inflate'),
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
