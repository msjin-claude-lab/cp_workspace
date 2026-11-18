# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(칸당 50개)와 직접 만든 단어장으로 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 칸별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

## 인계 — 새 세션은 여기부터 읽는다

- 지금 단계: **3. 선택 (대기)** — 2단계(선택안) 완료 · 2026-11-18 사내망 PC
- 멈춘 곳: `options.md`에 후보 4개(Expo·Flutter·KMP·.NET MAUI)와 장단점까지. 아직 고르지 않음
- 다음 할 일: `/apps:selection-subject vocab` → 3단계 AskUserQuestion으로 고르고, 고른 것과 이유를 `options.md` "3단계" 절에. 고르기 전에 유료 Apple Developer Program(연 $99) 가입 여부를 정한다
- 주의할 것: 어느 후보든 실제 아이폰 설치에는 유료 Apple 계정 또는 Mac이 필요하다(`options.md` "먼저 알아 둘 것"). 사내망 PC 설치 가능 여부는 어느 후보도 시험하지 않음. 4단계(검증)는 개인 PC에서만

## 파일

- [spec.md](spec.md) — 1단계 명세(deep-interview 원본 `.omc/specs/deep-interview-vocab.md` 복사)
- [options.md](options.md) — 2단계 후보 4개와 장단점(3단계에서 고른 것과 이유를 덧붙임)
- `verify.md` — 아직 없음(4단계)

## 진행 이력

- 2026-11-17 사내망 · 후보 · 앱 그룹을 만들며 "캘린더형·기록형(먼저), 게임형(나중)"이 후보로 이야기됨. 영단어 앱은 아직 없음
- 2026-11-18 사내망 · 1단계 시작 · `/apps:new` → `/oh-my-claudecode:deep-interview`로 영단어 앱(초·중·고) 인터뷰
- 2026-11-18 사내망 · 1단계 완료 · 7라운드, 모호도 약 19%(기준 20%). 9칸 × 50단어, 카드 학습·4지선다·오답 노트·진도, 계정 없음, TTS만. 명세 요약은 HANDOFF·`projects/apps/CLAUDE.md`에 적음
- 2026-11-18 사내망 · 수정 · 주제 폴더 방식으로 옮김 — 명세를 `spec.md`로 복사, 진행 상태를 이 README로. HANDOFF·`projects/apps/CLAUDE.md`의 vocab 내용은 정리
- 2026-11-18 사내망 · 수정 · README에 "인계" 절을 둠(주제 인계 규칙). 다음 할 일은 `/apps:selection-subject vocab`로
- 2026-11-18 사내망 · 2단계 완료 · `/apps:selection-subject vocab` → `/oh-my-claudecode:research`(공식 문서 조사 2갈래)로 후보 4개(Expo·Flutter·KMP·.NET MAUI)와 장단점을 `options.md`에. 어느 쪽이든 아이폰 설치에 유료 Apple 계정 또는 Mac 필요
