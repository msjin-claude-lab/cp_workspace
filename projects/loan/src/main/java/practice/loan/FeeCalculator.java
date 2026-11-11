package practice.loan;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * 연체료 계산.
 *
 * <p>규정:
 * <ul>
 *   <li>반납 예정일 당일까지 반납하면 연체료는 없다.</li>
 *   <li>유예 기간은 {@value #GRACE_DAYS}일이다. 유예 기간 안에 반납하면 연체료는 없다.</li>
 *   <li>유예 기간을 넘기면 <b>넘긴 일수에 대해서만</b> 하루 {@value #DAILY_FEE}원을 부과한다.
 *       예를 들어 5일 연체는 유예 3일을 뺀 2일치 = 1000원이다.</li>
 *   <li>연체료는 {@value #MAX_FEE}원을 넘지 않는다.</li>
 * </ul>
 */
public class FeeCalculator {

    public static final int GRACE_DAYS = 3;
    public static final int DAILY_FEE = 500;
    public static final int MAX_FEE = 10000;

    /**
     * 연체료를 원 단위로 계산한다.
     *
     * @param dueDate    반납 예정일
     * @param returnDate 실제 반납일
     * @return 연체료(원). 연체가 아니면 0.
     */
    public int calculate(LocalDate dueDate, LocalDate returnDate) {
        if (dueDate == null || returnDate == null) {
            throw new IllegalArgumentException("dueDate와 returnDate는 필수다");
        }

        long daysLate = ChronoUnit.DAYS.between(dueDate, returnDate);
        if (daysLate <= GRACE_DAYS) {
            return 0;
        }

        long fee = daysLate * DAILY_FEE;
        return (int) Math.min(fee, MAX_FEE);
    }
}
