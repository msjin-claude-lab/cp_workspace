---
title: "Gitea 로그인 - OAuth 만료와 wincred"
tags: ["git", "gitea", "credential", "gcm", "wincred", "oauth", "push"]
created: 2026-11-16T12:16:39.695Z
updated: 2026-11-16T12:16:39.695Z
sources: ["session 4e00985a 2026-11-15~16"]
links: ["hud.md"]
category: debugging
confidence: high
schemaVersion: 1
---

# Gitea 로그인 - OAuth 만료와 wincred

## 증상
- 사람이 `! git push`하면 되는데, Claude의 비대화식 push(`GIT_TERMINAL_PROMPT=0`)와 정시 점검 hook의 fetch는 `remote: Failed to authenticate user`로 실패했다.
- 몇 시간 지나면 사람의 push도 같은 오류로 실패했고, 로그인 창도 뜨지 않았다.

## 원인
1. Git Credential Manager(GCM)는 서버가 **Gitea인 것을 알아보면 OAuth로 로그인**한다(gcmcore.dll에 Gitea·oauth* 설정 문자열 확인). Windows 자격 증명에 사용자 `OAUTH_USER`와 `refresh_token.<호스트>` 항목이 생긴다. OAuth 출입증은 짧게 만료되고, 비대화식 실행에서는 갱신되지 않았다.
2. 이후 전역 설정이 `credential.http://222.112.172.253:9080.helper = "" , wincred`로 바뀌어 있었다. wincred는 저장된 값을 그대로 줄 뿐 갱신·로그인 창이 없어, 만료된 OAuth 값을 계속 보냈다.

## 해결
- `cmdkey /delete:"LegacyGeneric:target=git:http://222.112.172.253:9080"`(와 refresh_token 항목)로 만료된 값을 지움
- **별도 PowerShell 창**에서 `git push` → Username에 Gitea 계정, Password에 **개인 액세스 토큰**. wincred는 터미널 입력을 받으므로 Claude의 `!`에서는 입력할 수 없다
- 저장 후 항목 사용자가 `OAUTH_USER`가 아니라 계정 이름이면 성공. 비대화식 `git push --dry-run`이 `Everything up-to-date`

## 지금 기준
`env/git/git-config.json`에 helper = `"", wincred`를 모든 PC 기준으로 둠. 관련: [[hud-설정-우선순위와-출력-모양]]

