---
title: "loan 모듈 - 대출·반납·연장 구조"
tags: ["loan", "architecture", "checkout", "return", "renewal", "fee", "practice"]
created: 2026-11-17T06:55:21.836Z
updated: 2026-11-17T06:55:21.836Z
sources: ["projects/practice/loan/src/main/java/practice/loan (2026-11-17, 사내망 PC)"]
links: ["maven-surefire.md"]
category: architecture
confidence: high
schemaVersion: 1
---

# loan 모듈 - 대출·반납·연장 구조

# loan 모듈 - 대출·반납·연장 구조

`projects/practice/loan`(Java 8 타깃, 결함 의도적)의 동작 지도. 코드 위치는 `src/main/java/practice/loan/`.

## 구성
| 클래스 | 역할 |
|---|---|
| `LoanService` | 대출(`checkout`)·반납(`returnBook`)·활성 대출 조회(`findActiveLoans`). 대출 목록을 **메모리 `List<Loan>`** 에 보관(영속화 없음) |
| `FeeCalculator` | 연체료 계산 — `LoanService.returnBook`이 호출 |
| `RenewalPolicy` | 연장 가능 판단(`canRenew`)·새 예정일(`renew`) — **`LoanService`에 연결돼 있지 않음** |
| `AdminGate` | 관리자 인증·회원 검색 쿼리·감사 줄 (과제 4에서 보안 수정) |
| `Book` / `Member` / `Loan` | 값 객체. `Book.available`, `Member.suspended`, `Loan.returnedOn`·`renewalCount`가 상태 |

## 대출 `checkout(member, book, today)`
1. 인자 null → `IllegalArgumentException`
2. 정지 회원 / 이미 대출 중인 도서 / 활성 대출 `MAX_ACTIVE_LOANS`(5)권 이상 → `IllegalStateException`
3. `Loan(today, today + LOAN_DAYS(14))` 생성, `book.setAvailable(false)`, 목록에 추가

## 반납 `returnBook(member, book, today)` → 연체료(원)
1. 그 회원의 활성 대출 중 ISBN이 같은 것을 찾음(없으면 `IllegalStateException`)
2. `returnedOn = today`, 도서 `available = true`
3. `FeeCalculator.calculate(dueDate, today)` 반환

## 연체료 규정 (`FeeCalculator`)
- 연체일 = `dueDate`→`returnDate` 일수. **유예 3일 이내면 0원**
- 넘기면 (연체일 − 3) × 500원, 상한 10,000원. 예: 5일 연체 → 1,000원
- 과제 1에서 고친 곳이 "유예일을 빼지 않던" 계산이다

## 연장 규정 (`RenewalPolicy`)
- 최대 2회, 이미 연체(오늘 > 예정일)·정지 회원·다른 회원 예약 중이면 불가
- 새 예정일 = **기존 예정일** + 14일 (오늘 기준 아님)
- 과제 2에서 TDD로 구현. `Loan.renewalCount`를 올리고 `dueDate`를 바꾸는 서비스 메서드는 아직 없다

## 알아 둘 점
- 상태가 메모리에만 있어 `LoanService` 인스턴스마다 대출 기록이 따로다
- `Book.available`은 대출 기록과 별도로 들고 있는 플래그라, 서비스를 거치지 않고 바꾸면 기록과 어긋날 수 있다
- 과제 7(`/blast-radius`)의 재료: `Loan`에 상태 필드를 추가하면 `LoanService`·테스트가 함께 흔들린다

관련: [[maven-surefire]]

