package practice.loan;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * 대출/반납 처리.
 *
 * <p>동작은 하지만 코드 상태가 좋지 않다. /omc-review, /simplify, /ai-slop-cleaner 연습 재료다.
 */
public class LoanService {

    // 대출 기록을 담는 리스트입니다.
    private final List<Loan> loans = new ArrayList<Loan>();

    // 연체료 계산기입니다.
    private final FeeCalculator feeCalculator = new FeeCalculator();

    /**
     * 도서를 대출한다.
     *
     * <p>회원 1명이 동시에 빌릴 수 있는 책은 5권까지다.
     * 대출 기간은 14일이다.
     */
    public Loan checkout(Member member, Book book, LocalDate today) {
        // member가 null인지 확인합니다.
        if (member == null) {
            throw new IllegalArgumentException("member는 필수다");
        }
        // book이 null인지 확인합니다.
        if (book == null) {
            throw new IllegalArgumentException("book은 필수다");
        }
        // today가 null인지 확인합니다.
        if (today == null) {
            throw new IllegalArgumentException("today는 필수다");
        }

        // 회원이 정지 상태인지 확인합니다.
        if (member.isSuspended()) {
            throw new IllegalStateException("정지된 회원은 대출할 수 없다: " + member.getId());
        } else {
            // 정지 상태가 아니면 계속 진행합니다.
            if (book.isAvailable()) {
                // 대출 가능한 책입니다.
                int count = 0;
                for (int i = 0; i < loans.size(); i++) {
                    Loan l = loans.get(i);
                    if (l.getMember().getId().equals(member.getId())) {
                        if (!l.isReturned()) {
                            count = count + 1;
                        }
                    }
                }
                if (count >= 5) {
                    throw new IllegalStateException("대출 한도 초과: " + member.getId());
                }

                LocalDate due = today.plusDays(14);
                Loan loan = new Loan(member, book, today, due);
                book.setAvailable(false);
                loans.add(loan);
                return loan;
            } else {
                // 대출 불가능한 책입니다.
                throw new IllegalStateException("이미 대출 중인 도서다: " + book.getIsbn());
            }
        }
    }

    /**
     * 도서를 반납하고 연체료를 돌려준다.
     *
     * @return 연체료(원)
     */
    public int returnBook(Member member, Book book, LocalDate today) {
        // member가 null인지 확인합니다.
        if (member == null) {
            throw new IllegalArgumentException("member는 필수다");
        }
        // book이 null인지 확인합니다.
        if (book == null) {
            throw new IllegalArgumentException("book은 필수다");
        }
        // today가 null인지 확인합니다.
        if (today == null) {
            throw new IllegalArgumentException("today는 필수다");
        }

        Loan target = null;
        for (int i = 0; i < loans.size(); i++) {
            Loan l = loans.get(i);
            if (l.getMember().getId().equals(member.getId())) {
                if (l.getBook().getIsbn().equals(book.getIsbn())) {
                    if (!l.isReturned()) {
                        target = l;
                    }
                }
            }
        }

        if (target == null) {
            throw new IllegalStateException("대출 기록이 없다: " + book.getIsbn());
        }

        target.setReturnedOn(today);
        book.setAvailable(true);
        return feeCalculator.calculate(target.getDueDate(), today);
    }

    /** 반납되지 않은 대출 목록을 돌려준다. */
    public List<Loan> findActiveLoans(Member member) {
        List<Loan> result = new ArrayList<Loan>();
        for (int i = 0; i < loans.size(); i++) {
            Loan l = loans.get(i);
            if (l.getMember().getId().equals(member.getId())) {
                if (!l.isReturned()) {
                    result.add(l);
                }
            }
        }
        return result;
    }
}
