package practice.loan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** 대출/반납 동작. 전부 통과하는 것이 정상이다. */
class LoanServiceTest {

    private LoanService service;
    private Member member;
    private Book book;
    private final LocalDate today = LocalDate.of(2026, 3, 1);

    @BeforeEach
    void setUp() {
        service = new LoanService();
        member = new Member("M-001", "김연습", "practice@example.com");
        book = new Book("978-0", "리팩터링");
    }

    @Test
    @DisplayName("대출하면 반납 예정일은 14일 뒤이고 도서는 대출 불가가 된다")
    void checkoutSetsDueDateAndMarksUnavailable() {
        Loan loan = service.checkout(member, book, today);

        assertEquals(today.plusDays(14), loan.getDueDate());
        assertFalse(book.isAvailable());
        assertFalse(loan.isReturned());
    }

    @Test
    @DisplayName("이미 대출 중인 도서는 대출할 수 없다")
    void cannotCheckoutUnavailableBook() {
        service.checkout(member, book, today);
        Member other = new Member("M-002", "이연습", "other@example.com");

        assertThrows(IllegalStateException.class, () -> service.checkout(other, book, today));
    }

    @Test
    @DisplayName("정지된 회원은 대출할 수 없다")
    void suspendedMemberCannotCheckout() {
        member.setSuspended(true);

        assertThrows(IllegalStateException.class, () -> service.checkout(member, book, today));
    }

    @Test
    @DisplayName("동시 대출은 5권까지다")
    void checkoutLimitIsFive() {
        for (int i = 0; i < 5; i++) {
            service.checkout(member, new Book("978-" + i, "책" + i), today);
        }

        Book sixth = new Book("978-X", "여섯 번째");
        assertThrows(IllegalStateException.class, () -> service.checkout(member, sixth, today));
    }

    @Test
    @DisplayName("예정일에 반납하면 연체료가 없고 도서는 다시 대출 가능해진다")
    void returnOnDueDateHasNoFee() {
        Loan loan = service.checkout(member, book, today);

        int fee = service.returnBook(member, book, loan.getDueDate());

        assertEquals(0, fee);
        assertTrue(book.isAvailable());
        assertTrue(loan.isReturned());
    }

    @Test
    @DisplayName("대출 기록이 없는 반납은 거부한다")
    void returnWithoutLoanIsRejected() {
        assertThrows(IllegalStateException.class, () -> service.returnBook(member, book, today));
    }

    @Test
    @DisplayName("반납한 대출은 활성 목록에서 빠진다")
    void returnedLoanLeavesActiveList() {
        service.checkout(member, book, today);
        assertEquals(1, service.findActiveLoans(member).size());

        service.returnBook(member, book, today.plusDays(1));

        assertEquals(0, service.findActiveLoans(member).size());
    }

    @Test
    @DisplayName("필수 인자가 없으면 거부한다")
    void rejectsNullArguments() {
        assertThrows(IllegalArgumentException.class, () -> service.checkout(null, book, today));
        assertThrows(IllegalArgumentException.class, () -> service.checkout(member, null, today));
        assertThrows(IllegalArgumentException.class, () -> service.checkout(member, book, null));
    }

    @Test
    @DisplayName("ISBN이 같은 다른 객체로 반납해도 빌려 간 도서가 다시 대출 가능해진다")
    void returnWithEqualIsbnBookFreesLoanedBook() {
        service.checkout(member, book, today);

        service.returnBook(member, new Book("978-0", "리팩터링"), today.plusDays(1));

        assertTrue(book.isAvailable());
    }

    @Test
    @DisplayName("ISBN이 같은 다른 객체로도 이미 대출 중인 도서는 다른 회원이 대출할 수 없다")
    void cannotCheckoutOnLoanIsbnViaDifferentBookInstance() {
        service.checkout(member, book, today);
        Member other = new Member("M-002", "이연습", "other@example.com");

        assertThrows(IllegalStateException.class,
                () -> service.checkout(other, new Book("978-0", "리팩터링"), today));
    }

    @Test
    @DisplayName("ISBN이 같은 다른 객체로도 같은 회원이 이중 대출할 수 없다")
    void cannotCheckoutOnLoanIsbnTwiceBySameMember() {
        service.checkout(member, book, today);

        assertThrows(IllegalStateException.class,
                () -> service.checkout(member, new Book("978-0", "리팩터링"), today));
    }

    @Test
    @DisplayName("반납한 도서는 다른 객체로도 다시 대출할 수 있다")
    void canCheckoutAgainAfterReturn() {
        service.checkout(member, book, today);
        service.returnBook(member, book, today.plusDays(1));
        Member other = new Member("M-002", "이연습", "other@example.com");

        Book again = new Book("978-0", "리팩터링");
        service.checkout(other, again, today.plusDays(2));

        assertFalse(again.isAvailable());
    }

    @Test
    @DisplayName("활성 대출 조회에 회원이 없으면 거부한다")
    void findActiveLoansRejectsNullMember() {
        assertThrows(IllegalArgumentException.class, () -> service.findActiveLoans(null));
    }
}
