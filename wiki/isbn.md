---
title: "결정 - 예약 기능은 ISBN 키 예약 대장으로 둔다"
tags: ["loan", "reservation", "decision", "architect", "practice-7"]
created: 2026-11-17T07:55:46.334Z
updated: 2026-11-17T07:55:46.334Z
sources: ["/oh-my-claudecode:architect 2026-11-17 사내망 PC", "blast-radius v3 probe", "DoubleCheckoutProbeTest"]
links: ["loan.md"]
category: decision
confidence: high
schemaVersion: 1
---

# 결정 - 예약 기능은 ISBN 키 예약 대장으로 둔다

# 결정 - 예약 기능은 ISBN 키 예약 대장으로 둔다

과제 7(`/blast-radius` → `/architect`), 2026-11-17 사내망 PC. 설계만 정했고 구현은 아직이다.

## 문제
반납된 책을 예약한 회원이 먼저 빌리게 하고, 대기 예약이 있으면 연장을 막는다.

## 지켜야 할 조건
- I1 같은 ISBN의 어느 `Book` 객체로 접근해도 예약이 보인다 (blast-radius v3 탐침 실패에서 나옴)
- I2 예약 보관 중인 책은 예약자만 대출 · I3 대기 예약이 있으면 연장 불가
- I4 기존 공개 API·테스트 37개 유지 · I5 Java 8 · I6 메모리 저장

## 후보
- **A. Book에 예약 필드 + ISBN→Book 정규화 맵**: 기존 테스트 무변경. 그러나 진실 원천이 사실상 LoanService의 맵인데 상태는 공개 가변 객체에 있어, 정규본이 아닌 Book은 조용히 틀린 값을 보여 준다(I1 부분 충족). 예약 규칙이 Book·LoanService 두 곳에 나뉜다
- **B. ISBN 키 예약 대장(`ReservationLedger`) + LoanService 생성자 주입**: Book·RenewalPolicy·기존 테스트 무변경. I1이 구조적으로 성립(키가 ISBN 문자열). 대장을 따로 테스트할 수 있다
- **C. 서지(Title)·소장본(Copy) 분리 + Catalog**: I1~I6 충족. 새 클래스 5개로 가장 크고, 지금 API는 사본 ID를 지정할 수 없어 사본은 늘 1권 — Copy 계층이 쓰이지 않는 추상화가 된다

## 결정: B
- A보다 나은 점: I1을 "같은 맵을 거칠 때만"이 아니라 키 설계로 보장한다. 예약 규칙이 한 곳(대장)에 모인다
- C보다 나은 점: 같은 이득을 새 클래스 2개로 얻는다. 여러 권 요구가 생기면 대장 키를 ISBN 그대로 두고 C로 넓힐 수 있다(지우기·확장 쉬움)
- C를 버린 이유: 사본 여러 권 요구가 아직 없다(YAGNI). 생기면 다시 연다

## 허용한 변경 (구현 때 맞춰 볼 목록)
1. **`checkout`의 대출 가능 판정을 `book.isAvailable()`에서 `loans`의 ISBN 조회로 바꾼다.** 이유: 지금도 같은 ISBN의 다른 Book 객체로 대출 중인 책을 또 빌릴 수 있다 — `DoubleCheckoutProbeTest` 실행 결과 38개 중 1개 실패로 확인(2026-11-17). B 단독으로는 이 구멍을 못 막는다(B 설계자도 약점으로 지목). `Book.available`은 테스트(LoanServiceTest 34·74·110행)가 보므로 계속 갱신한다
2. 보관 만료는 시계 없이 `today`를 받는 호출 때 지연 계산한다
3. `LoanService`에 `reserve`, `renew`를 추가한다. `renew`가 `ledger.hasWaitingByOther(isbn, member)`로 `reservedByOther`를 계산해 `RenewalPolicy.canRenew`에 넘긴다(시그니처 그대로)

## 다음
`/oh-my-claudecode:tdd` 또는 `execute`로 구현. 위 탐침 2개(예약 우회, 이중 대출)를 첫 테스트로 쓴다.

관련: [[loan]]

