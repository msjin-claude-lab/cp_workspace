---
name: config
description: apps 플러그인 관리 모드 — 호출한 때부터 사용자가 종료를 지시할 때까지 apps 플러그인(스킬·매니페스트·마켓플레이스)만 관리한다
disable-model-invocation: true
---

# /apps:config

이 스킬을 부른 때부터 사용자가 **종료를 지시할 때까지**(예: "config 종료", "관리 모드 끝") 이 대화는 apps 플러그인 관리만 한다.

## 다루는 범위

- `plugins/apps/**` — 스킬(`skills/<이름>/SKILL.md`), `.claude-plugin/plugin.json`
- 루트 `.claude-plugin/marketplace.json`의 `apps` 항목
- `HANDOFF.md` "남은 일" 표의 `/apps:` 플러그인 행(플러그인 기록)

이 밖의 요청(앱 작업 자체, loan, 환경 설정 등)은 하지 않는다. "apps 플러그인 관리 모드라 범위 밖"이라고 알리고, 관리 모드를 끝낼지 AskUserQuestion으로 묻는다. 세션 시작·정시 git 점검 hook의 질문에는 답하되, 커밋에는 위 범위의 파일만 넣는다.

## 시작할 때

1. "apps 플러그인 관리 모드 시작"이라고 알린다
2. 현재 상태를 짧게 보여 준다: `plugin.json`의 버전, `plugins/apps/skills/` 아래 스킬 목록과 각 `description`
3. 무엇을 할지 묻는다(스킬 추가·수정·삭제, 버전, 설명 등)

## 바꿀 때마다

- 한글·백슬래시가 든 파일은 Edit/Write 도구로만 고친다(루트 CLAUDE.md "작업 규칙")
- 스킬을 추가·삭제하거나 동작을 바꾸면 `plugin.json`의 `version`을 올린다(추가·동작 변경은 minor, 문구만 고치면 patch)
- 확인: `claude plugin validate plugins/apps`와 `claude plugin validate .`가 종료 코드 0, 고친 파일에 제어 문자(`\x00-\x08`) 0개. LICENSE·아이콘 경고는 공개 목록 등록용이라 무시한다
- 반영: 원본 폴더를 그대로 읽으므로 재설치 없이 `/reload-plugins`. 화면에 뜨는지는 사용자 확인 전까지 "화면 확인 필요"로 보고한다
- HANDOFF의 `/apps:` 플러그인 행에 무엇을 바꿨는지 한 줄 덧붙인다
- 커밋·push는 사용자에게 묻고, `origin`(Gitea)에만 한다

## 끝낼 때

사용자가 종료를 지시하면 "apps 플러그인 관리 모드 종료"라고 알리고, 커밋하지 않은 플러그인 변경이 있으면 그 목록을 보여 준다. 그 뒤로는 범위 제한 없이 평소대로 일한다.
