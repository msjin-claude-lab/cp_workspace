# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(칸당 50개)와 직접 만든 단어장으로 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 칸별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

## 인계 — 새 세션은 여기부터 읽는다

- 지금 단계: **2. 선택안 (대기)** — 1단계(앱 정의) 완료 · 2026-11-18 사내망 PC
- 멈춘 곳: 1단계 명세(`spec.md`)까지. 2단계는 아직 시작하지 않음
- 다음 할 일: `/apps:selection-subject vocab` → 2단계 `/oh-my-claudecode:research`로 안드로이드·iOS 둘 다 지원하는 언어·플랫폼 후보 2~4개를 `options.md`에. 장단점에 넣을 것: iOS 빌드의 macOS 필요 여부와 Windows 대안(클라우드 빌드), TTS 양쪽 지원, 기기 안 저장소, 사내망 `github.com` 차단
- 주의할 것: 2단계는 조사만이라 어느 PC에서든 된다. 4단계(검증)는 개인 PC에서만

## 파일

- [spec.md](spec.md) — 1단계 명세(deep-interview 원본 `.omc/specs/deep-interview-vocab.md` 복사)
- `options.md` — 아직 없음(2·3단계)
- `verify.md` — 아직 없음(4단계)

## 진행 이력

- 2026-11-17 사내망 · 후보 · 앱 그룹을 만들며 "캘린더형·기록형(먼저), 게임형(나중)"이 후보로 이야기됨. 영단어 앱은 아직 없음
- 2026-11-18 사내망 · 1단계 시작 · `/apps:new` → `/oh-my-claudecode:deep-interview`로 영단어 앱(초·중·고) 인터뷰
- 2026-11-18 사내망 · 1단계 완료 · 7라운드, 모호도 약 19%(기준 20%). 9칸 × 50단어, 카드 학습·4지선다·오답 노트·진도, 계정 없음, TTS만. 명세 요약은 HANDOFF·`projects/apps/CLAUDE.md`에 적음
- 2026-11-18 사내망 · 수정 · 주제 폴더 방식으로 옮김 — 명세를 `spec.md`로 복사, 진행 상태를 이 README로. HANDOFF·`projects/apps/CLAUDE.md`의 vocab 내용은 정리
- 2026-11-18 사내망 · 수정 · README에 "인계" 절을 둠(주제 인계 규칙). 다음 할 일은 `/apps:selection-subject vocab`로
