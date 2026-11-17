---
title: "HUD 설정 우선순위와 출력 모양"
tags: ["hud", "omc", "statusline", "hud-config", "omcHud", "wrapper"]
created: 2026-11-16T12:16:40.487Z
updated: 2026-11-16T12:16:40.487Z
sources: ["session 4e00985a 2026-11-16", "omc dist/hud/state.js readHudConfig"]
links: ["gitea-oauth-wincred.md"]
category: environment
confidence: high
schemaVersion: 1
---

# HUD 설정 우선순위와 출력 모양

## OMC가 HUD 설정을 읽는 순서
`~/.claude/settings.json`의 **`omcHud` 키 > `~/.claude/.omc/hud-config.json` > 기본값** (OMC `dist/hud/state.js`의 `readHudConfig`). `/oh-my-claudecode:hud`는 `omcHud`에 쓴다. 그래서 hud-config.json만 맞추면 `omcHud`가 있는 PC에서는 적용되지 않는다.

## PC마다 출력 모양이 다를 수 있다
- 배치(`layout.main`/`detail`)에 따라 ctx가 다른 항목 뒤에 붙기도(사내망 PC), 혼자 한 줄에 있기도(개인 PC) 한다
- 개인 PC의 OMC는 `Model: Opus 5.5`의 공백을 **U+00A0(줄바꿈 금지 공백)**으로 낸다. 정규식은 공백 대신 `\s`(U+00A0 포함)를 쓴다
- 상태창은 여러 줄이면 **첫 줄만** 보여 주고 나머지를 접는다 → 늘 볼 값은 첫 줄에

## 미리보기·렌더링에서 알게 된 것 (2026-11-17 사내망 PC, Zed 터미널)
- **대화창의 `!` 출력은 ANSI 색을 그리지 않는다** — 색 코드가 글자로 찍힌다. 색 견본은 상태줄이나 별도 터미널에서 본다
- **Zed 터미널은 색과 밑줄을 한 SGR에 묶으면(`\e[38;5;208;4m`) 통째로 버린다.** 속성을 하나씩 따로 보내면(`\e[38;5;208m\e[4m`) 그려진다
- **Claude Code는 상태줄 각 줄 앞의 공백을 `trim()`한다.** U+00A0도 잘린다. 들여쓰기는 공백이 아닌 U+2800(점자 빈칸)으로 한다
- **OMC는 출력을 `maxOutputLines`(기본 4)줄로 자른다.** 에이전트가 돌면 agents 줄이 늘어 뒤쪽 항목(예전엔 ctx)이 잘렸다 → `contextBar`를 detail 맨 앞에 두고, 래퍼가 ctx를 stdin 사용률로 다시 만든다
- 래퍼를 손으로 시험할 때 stdin JSON의 Windows 경로는 `/`로 쓴다(`\`를 printf로 넣다 JSON이 깨진 적 있음). stdin 없이 래퍼를 import하면 입력을 기다리며 멈춘다

## git 상태 기호
래퍼가 직접 `git status --porcelain=v2 --branch`로 그린다: `M2`(커밋 안 한 변경), `+1`(새 파일), `↑1`/`↓2`(올릴/받을 커밋). `✎` 같은 기호는 동아시아 터미널에서 폭이 모호해 뒤 글자와 겹쳐 보여서 영문 `M`으로 바꿨다.

## 지금 기준
`env/hud/`(래퍼, hud-config.json)가 기준이고 `env/sync.mjs`가 세션 시작·pull 직후 자동으로 맞추며 `omcHud`는 지운다. 관련: [[gitea-로그인-oauth-만료와-wincred]]

