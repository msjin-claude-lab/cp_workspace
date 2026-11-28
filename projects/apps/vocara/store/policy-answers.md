# Vocara — Play Console "앱 콘텐츠" 답안 초안

Play Console → 정책 → 앱 콘텐츠의 항목마다 답과 근거를 적었다. 2026-11-28 개인 PC에서 코드로 확인한 사실이 근거이고, **2026-11-29 AdMob 배너 광고를 넣으며 광고·데이터 보안·가족 정책 부분을 다시 썼다**(공식 문서 조사는 `.omc/research/vocab-ads.md` — 저장소 밖이라 근거 링크는 아래에 옮겨 적었다). **설문 문항의 실제 문구는 등록할 때 화면에서 다시 읽고 고른다** — 여기 문항 이름은 Play Console 화면을 직접 보지 않고 적은 것이다.

## 근거로 쓴 앱 사실

| 사실 | 확인한 곳 |
|---|---|
| 권한(광고를 넣은 뒤) | release 병합 매니페스트(`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`, 2026-11-29 광고 뒤 AAB 빌드)의 `uses-permission`: `POST_NOTIFICATIONS`(매일 알림)·`RECEIVE_BOOT_COMPLETED`(재부팅 뒤 알림 다시 예약)·`VIBRATE`(알림 패키지)·**`INTERNET`·`ACCESS_NETWORK_STATE`·`WAKE_LOCK`·`FOREGROUND_SERVICE`(광고 SDK가 넣음)**·`kr.msjin.vocab.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`(AndroidX 내부). **`AD_ID`와 `ACCESS_ADSERVICES_AD_ID`·`_ATTRIBUTION`·`_TOPICS`는 없다** — `android/app/src/main/AndroidManifest.xml`에서 `tools:node="remove"`로 뺐다. 정확한 알람 권한 없음 |
| 계정·로그인 없음 | 앱에 로그인 화면·인증 패키지 없음(`pubspec.yaml` 의존성: flutter_tts, sqflite, path, go_router, flutter_riverpod, shared_preferences, flutter_local_notifications, timezone, google_mobile_ads) |
| 학습 기록은 기기 안에만 | sqflite(`lib/data/` 학습·시험·오답·단어장·오늘의 단어 `daily_words`), shared_preferences(고른 단어장, 매일 알림 켜짐·시각) — 광고 SDK에 넘기지 않는다 |
| 알림은 기기 안 예약 | `flutter_local_notifications`의 로컬 예약 알림(`lib/features/reminder/`) — 서버 푸시·Firebase 없음 |
| 광고는 AdMob 배너 하나 | `google_mobile_ads` 9.2.0(`lib/features/ads/`). 홈·오답 노트·진도·설정·단어장이 없을 때의 시작 화면·새 단어장 만들기 아래에 배너 1개, 카드·오늘의 단어·시험·오답 시험·앱 정보에는 없음. 모든 요청에 `ageRestrictedTreatment.child` + `tagForChildDirectedTreatment.yes` + `maxAdContentRating.g`. debug는 Google 테스트 광고 단위, release는 실제 단위. 분석·Firebase 패키지는 없음 |
| 결제 없음 | 결제 패키지 없음 |
| 발음은 기기 TTS | `flutter_tts`, 매니페스트 `<queries>`의 `TTS_SERVICE` |
| 단어에 민감한 말이 사전적 뜻으로 있다 | 심화 칸 `assets/words/advanced_*.json` — 예: damn "(욕설) 빌어먹을", bloody "(영국 욕설) 빌어먹을", hell "지옥, (비속어로 쓰여) 도대체·젠장", gook "(아시아인을 낮잡는) 인종 비하어", retard "늦추다, 지체 장애인을 낮춰 부르는 욕", rape "강간, 성폭력", sexual "성적인, 성과 관련된" 등 25개(4차 5단계 사용자 결정 "다 넣는다", HANDOFF 인계) |

## 1. 개인정보처리방침

- 답: Google Sites에 게시한 `privacy-policy.md`의 주소 → `https://sites.google.com/view/vocara-privacy`(2026-11-29 게시, 로그인 없이 열림 확인)

## 2. 광고

- 답: **예, 앱에 광고가 있습니다**(스토어에 "광고 포함"이 표시된다)
- 이 항목의 Play 공식 안내 페이지는 조사 때 읽지 못했다 — 화면 설명을 읽고 고른다

## 3. 앱 액세스 권한

- 답: **모든 기능을 특별한 액세스 권한 없이 이용할 수 있음**(로그인·구독·위치 제한 없음)

## 4. 콘텐츠 등급(IARC 설문)

- 카테고리: **참고 자료, 뉴스 또는 교육**에 가까운 항목(설문 첫 화면의 분류에서 고른다)
- 폭력·공포·도박·약물·성적 콘텐츠를 **보여 주거나 묘사하는 장면은 없다** — 이미지·영상 없이 단어와 예문뿐
- **언어(욕설·비속어)와 차별적 표현**: 위 표처럼 심화 칸 단어장에 욕설·비하어가 **사전적 뜻과 함께** 들어 있다. 숨기지 말고 해당 문항에 **있음**으로 답하는 것을 권한다(사전·교육 목적이라는 설명란이 있으면 그렇게 적는다)
  - **주의(사용자 결정 필요)**: 이 답 때문에 등급이 전체 이용가보다 올라갈 수 있다(예: 12세 이상). 13세 미만을 대상에 넣은 것(5절)과 맞지 않게 나오면, 등록 전에 ① 등급을 받아들이기 ② 해당 말을 빼기(새 DB 판 필요 — 심화를 연 뒤라 번호가 바뀜) ③ 심화를 13세 이상 단어장으로 따로 두기 중에서 정한다. 어떤 등급이 나올지는 설문을 실제로 해 봐야 안다(확인하지 않음)
- 사용자 간 소통·공유·위치 공유·디지털 상품 구매: **없음**

## 5. 타겟층 및 콘텐츠

- 대상 연령: **5세 이하는 빼고, 6~8 · 9~12 · 13~15 · 16~17 · 18세 이상**(초등 단어부터 있으므로) — 13세 미만이 들어가므로 **가족 정책**을 따른다
- 앱이 아동의 관심을 끌 만한가: 학습 앱 — 위 대상 연령을 고르면 자동으로 가족 정책 대상이 된다
- 가족 정책에서 확인할 것(광고를 넣은 뒤):
  - **광고 SDK**: 가족 정책 자체 인증 광고 SDK만 써야 한다 — Google AdMob(play-services-ads) 19.0.0 이상이 목록에 있다(https://support.google.com/googleplay/android-developer/answer/9283445). 앱은 google_mobile_ads 9.2.0(Android SDK 25.5.0 번들)
  - **광고 ID**: 아동 대상 앱은 Android 광고 ID를 보내면 안 되고 API 33 이상에서 `AD_ID` 권한을 요청하지 말아야 한다(https://support.google.com/googleplay/android-developer/answer/9893335) → 권한을 뺐다(위 표). 권한이 없으면 광고 ID를 못 읽는 것은 Android 13 이상뿐이다 — 앱 minSdk는 24라 **Android 7~12에서 SDK가 어린이 대상 요청에 광고 ID를 보내지 않는지는 확인하지 못했다(등록 전 사용자 확인 — AdMob 어린이 대상 처리 안내)**
  - **광고 내용**: 관심 기반 광고·리마케팅 금지, 부적절한 광고 금지 → 모든 요청에 어린이 대상 처리 + 최대 등급 G. **AdMob 앱 설정에서도 광고 콘텐츠 등급 G로 둔다(사용자 — 아직 안 함)**
  - **배치**: 오클릭 유도·앱 콘텐츠처럼 보이는 광고·전면 광고 금지 → 화면당 배너 1개, 화면 맨 아래 고정, 공부 화면에는 없음. 홈의 "새 등록" 버튼과 겹치지 않음(2026-11-29 에뮬레이터 확인)
  - **나이 확인 화면이 없다**: 사용자 결정으로 나이를 묻지 않고 **모든 이용자를 어린이로 처리**한다. 가족 정책은 혼합 대상 앱에 중립적 나이 확인을 요구하는데, "모두 어린이 처리"가 이 요건을 채운다고 공식 문서가 밝힌 문구는 찾지 못했다 — **등록 전에 사용자가 확인**(Play Console 화면 안내 또는 정책 도움말)
  - 개인정보: 이름·연락처·위치는 모으지 않음. 광고 SDK가 보내는 정보는 6절
- "교사 승인" 배지 신청은 선택 — 이번 범위 밖

## 6. 데이터 보안

광고 SDK가 보내는 것을 선언한다. Play는 서드파티 SDK가 수집·처리하는 데이터도 선언하라고 한다(https://support.google.com/googleplay/android-developer/answer/10787469). AdMob의 공개 안내(https://developers.google.com/admob/android/privacy/play-data-disclosure)를 그대로 따른다 — 어린이 대상 처리를 하면 항목이 줄어드는지는 안내에 없어 **보수적으로 전부 선언**한다.

- 앱이 사용자 데이터를 수집하거나 공유하는가: **예**
- 선언할 데이터 유형 — 모두 **수집함 + 공유함**, 목적은 **광고 또는 마케팅 · 분석 · 사기 방지, 보안 및 규정 준수**:

  | Play 양식의 항목 | AdMob 안내의 항목 |
  |---|---|
  | 위치 → 대략적인 위치(Claude 추정 — IP 주소를 따로 넣는 칸이 양식에 없으면) | IP 주소. 양식의 어느 항목에 넣을지는 확인하지 않았다 — 등록 때 AdMob 안내 원문과 양식 설명을 보고 정한다 |
  | 앱 활동 → 앱 상호작용 | 사용자의 제품 상호작용(광고 보기·누르기 등) |
  | 앱 정보 및 성능 → 비정상 종료 로그 · 진단 | 진단 정보 |
  | 기기 또는 기타 식별자 | 기기 식별자(앱 세트 ID, Android 12 이하에서는 광고 ID도 가능 — 5절. 이 항목은 선언) |

  - 위 왼쪽 열의 짝짓기는 Claude가 양식 항목 이름에 맞춘 것이다 — **등록 때 AdMob 안내 원문의 표와 대조**한다
- 수집이 **필수인가 선택인가**: 필수(광고를 끄는 설정이 없다)
- 데이터가 **전송 중 암호화**되는가: **예**(AdMob 안내 "TLS로 전송 중 암호화")
- 사용자가 **데이터 삭제를 요청**할 수 있는가: 앱이 서버에 모으는 데이터가 없어 앱 쪽 삭제 요청 수단은 없다. 학습 기록은 앱 삭제로 지워지고(처리방침 3절), 광고 쪽 정보는 Google 처리방침을 따른다. 양식 문구를 보고 고른다
- 학습 기록(단어장·시험·오답 노트)·알림 설정은 기기에서만 처리되고 밖으로 나가지 않으므로 선언하지 않는다

## 7. 그 밖의 선언

| 항목 | 답 |
|---|---|
| 정부 앱 | 아니요 |
| 금융 기능 | 없음 |
| 건강 앱 | 아니요 |
| 뉴스 앱 | 아니요 |
| 코로나19 관련 | 아니요 |

## 광고를 넣으며 한 것 (2026-11-29)

처음 등록 전에 광고를 넣었다(원래 계획은 등록 뒤 업데이트였다). 한 것: AdMob 배너(위 표), 권한 정리, 2·5·6절 답 다시 쓰기, `privacy-policy.md` 처음 문단·1·2·4·7절, `listing.md` 자세한 설명의 광고 줄. **정책 문구는 조사 때 요약으로 읽은 것이라, 제출 전에 원문을 다시 확인한다.**

등록 전 사용자 몫: AdMob 앱 설정에서 광고 콘텐츠 등급 G, 5절의 "모두 어린이 처리" 확인, 5절의 Android 12 이하 광고 ID 확인, Play 출시 뒤 AdMob에서 스토어 연결·지급 정보.
