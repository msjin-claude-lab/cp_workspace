package practice.loan;

import java.time.LocalDate;

/** 한 건의 대출 기록. */
public class Loan {

    private final Member member;
    private final Book book;
    private final LocalDate checkedOutOn;
    private LocalDate dueDate;
    private LocalDate returnedOn;
    private int renewalCount;

    public Loan(Member member, Book book, LocalDate checkedOutOn, LocalDate dueDate) {
        this.member = member;
        this.book = book;
        this.checkedOutOn = checkedOutOn;
        this.dueDate = dueDate;
        this.renewalCount = 0;
    }

    public Member getMember() {
        return member;
    }

    public Book getBook() {
        return book;
    }

    public LocalDate getCheckedOutOn() {
        return checkedOutOn;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public void setDueDate(LocalDate dueDate) {
        this.dueDate = dueDate;
    }

    public LocalDate getReturnedOn() {
        return returnedOn;
    }

    public void setReturnedOn(LocalDate returnedOn) {
        this.returnedOn = returnedOn;
    }

    public int getRenewalCount() {
        return renewalCount;
    }

    public void setRenewalCount(int renewalCount) {
        this.renewalCount = renewalCount;
    }

    public boolean isReturned() {
        return returnedOn != null;
    }
}
