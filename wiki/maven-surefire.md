---
title: "Maven 검증 함정 - 오래된 surefire 결과 파일"
tags: ["maven", "verify", "surefire", "test", "offline"]
created: 2026-11-16T12:16:40.113Z
updated: 2026-11-16T12:16:40.113Z
sources: ["session 4e00985a 2026-11-15 과제 5"]
links: []
category: pattern
confidence: high
schemaVersion: 1
---

# Maven 검증 함정 - 오래된 surefire 결과 파일

## 일어난 일
`mvn -q -o clean test`가 `maven-clean-plugin`을 내려받은 적이 없어 오프라인 모드에서 **시작하자마자 실패**(종료 코드 1)했다. 그런데 `target/surefire-reports/*.txt`에는 지난 실행 결과가 남아 있어 "26개 모두 통과"로 보였다.

## 규칙
- 통과 판정은 **종료 코드 + 결과 파일이 방금 만들어졌는지(생성 시각)**로 한다. 결과 파일 내용만 보지 않는다
- `mvn -q`는 성공하면 아무것도 출력하지 않는다. "출력 없음"만으로 판정하지 않는다
- 처음 한 번은 `-o` 없이 실행해 플러그인을 받아 둔다

이 내용은 `.claude/skills/verify/SKILL.md`(이 저장소 전용 `/verify`)의 "함정" 절에도 있다.

