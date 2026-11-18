---
name: new
description: 새 앱을 시작한다 — projects/apps/CLAUDE.md의 5단계(앱 정의 → 선택안 → 선택 → 검증 → 최종 결정)를 지금 상태부터 이어서 진행한다
argument-hint: "[앱 아이디어]"
---

# /apps:new

순서와 규칙의 원본은 `projects/apps/CLAUDE.md`다. 이 스킬은 그 순서를 실제로 진행하는 방법만 정한다.

## 시작

1. `projects/apps/CLAUDE.md`를 읽고 **"지금 상태"의 단계부터** 이어 간다. 끝난 단계는 다시 하지 않는다
2. 한 번 실행에 **단계 하나만** 진행한다. 끝나면 다음 단계를 한 줄 표로 안내한다(루트 CLAUDE.md "답변 형식")
3. 단계를 끝낼 때마다 `projects/apps/CLAUDE.md` "지금 상태"(앱·단계·날짜·PC)를 고치고, 자세한 기록은 `HANDOFF.md` "앱" 절에 남긴다

## 단계별 진행

| 단계 | 하는 일 | 끝났다고 보는 기준 |
|---|---|---|
| 1. 앱 정의 | **이 대화 안에서** Skill 도구로 `/oh-my-claudecode:deep-interview`를 호출한다. 인자는 `$ARGUMENTS`, 비어 있으면 "지금 상태"의 후보. 정할 것: 기능·화면·데이터·대상 플랫폼. 언어·플랫폼은 정하지 않는다 | 인터뷰가 끝나 명세가 나오고, 그 요약이 HANDOFF "앱" 절에 있다(`.omc/specs/`는 git에 안 올라가 다른 PC에서 못 본다) |
| 2. 선택안 | `/oh-my-claudecode:research`로 그 앱에 맞는 언어·플랫폼 후보 2~4개를 장단점과 함께 조사한다. 사내망 PC의 `github.com` 차단, npm·Maven 가용(루트 CLAUDE.md "네트워크 제약")을 장단점에 넣는다 | 후보와 장단점이 HANDOFF에 있다 |
| 3. 선택 | AskUserQuestion으로 사용자가 고른다 | 고른 것과 이유가 HANDOFF에 있다 |
| 4. 검증 | **개인 PC에서만.** 먼저 `github.com` 접속 가능 여부로 PC를 판단한다. 사내망 PC면 진행하지 않고 "개인 PC에서 4단계 필요"로 기록하고 멈춘다. 개인 PC면 SDK 설치·빈 프로젝트 빌드·간단한 실행을 실제 명령으로 하고 `/oh-my-claudecode:verify`로 판정한다 | 명령과 종료 코드가 HANDOFF에 있다. 출력 문구만으로 통과라 하지 않는다 |
| 5. 최종 결정 | `projects/apps/<앱>/`와 그 `CLAUDE.md`(빌드·테스트 명령)를 만들고, 저장소 `/verify` 스킬(`.claude/skills/verify`)이 그 앱 명령도 보도록 고친다. 앱 이름은 짧게(Windows 경로 260자) | 앱 폴더·CLAUDE.md가 있고 `/verify`가 그 앱을 확인한다 |
