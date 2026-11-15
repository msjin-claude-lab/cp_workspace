package practice.loan;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** 대출/반납 처리. */
public class LoanService {

    public static final int MAX_ACTIVE_LOANS = 5;
    public static final int LOAN_DAYS = 14;

    private final List<Loan> loans = new ArrayList<>();
    private final FeeCalculator feeCalculator = new FeeCalculator();

    /**
     * 도서를 대출한다. 회원당 동시 대출은 {@value #MAX_ACTIVE_LOANS}권, 대출 기간은 {@value #LOAN_DAYS}일이다.
     */
    public Loan checkout(Member member, Book book, LocalDate today) {
        requireArgs(member, book, today);
        if (member.isSuspended()) {
            throw new IllegalStateException("정지된 회원은 대출할 수 없다: " + member.getId());
        }
        if (!book.isAvailable()) {
            throw new IllegalStateException("이미 대출 중인 도서다: " + book.getIsbn());
        }
        if (findActiveLoans(member).size() >= MAX_ACTIVE_LOANS) {
            throw new IllegalStateException("대출 한도 초과: " + member.getId());
        }

        Loan loan = new Loan(member, book, today, today.plusDays(LOAN_DAYS));
        book.setAvailable(false);
        loans.add(loan);
        return loan;
    }

    /**
     * 도서를 반납하고 연체료를 돌려준다.
     *
     * @return 연체료(원)
     */
    public int returnBook(Member member, Book book, LocalDate today) {
        requireArgs(member, book, today);

        Loan target = null;
        for (Loan loan : findActiveLoans(member)) {
            if (loan.getBook().getIsbn().equals(book.getIsbn())) {
                target = loan;
            }
        }
        if (target == null) {
            throw new IllegalStateException("대출 기록이 없다: " + book.getIsbn());
        }

        target.setReturnedOn(today);
        target.getBook().setAvailable(true);
        return feeCalculator.calculate(target.getDueDate(), today);
    }

    /** 반납되지 않은 대출 목록을 돌려준다. */
    public List<Loan> findActiveLoans(Member member) {
        if (member == null) {
            throw new IllegalArgumentException("member는 필수다");
        }
        List<Loan> result = new ArrayList<>();
        for (Loan loan : loans) {
            if (loan.getMember().getId().equals(member.getId()) && !loan.isReturned()) {
                result.add(loan);
            }
        }
        return result;
    }

    private static void requireArgs(Member member, Book book, LocalDate today) {
        if (member == null) {
            throw new IllegalArgumentException("member는 필수다");
        }
        if (book == null) {
            throw new IllegalArgumentException("book은 필수다");
        }
        if (today == null) {
            throw new IllegalArgumentException("today는 필수다");
        }
    }
}
