package practice.loan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 연체료 규정({@link FeeCalculator} javadoc)을 그대로 옮긴 테스트다.
 *
 * <p>이 중 하나는 <b>실패한다</b>. 의도된 것이다 — /debug, /trace 연습의 출발점이다.
 */
class FeeCalculatorTest {

    private final FeeCalculator calculator = new FeeCalculator();
    private final LocalDate due = LocalDate.of(2026, 3, 10);

    @Test
    @DisplayName("예정일 당일 반납은 연체료가 없다")
    void noFeeWhenReturnedOnDueDate() {
        assertEquals(0, calculator.calculate(due, due));
    }

    @Test
    @DisplayName("예정일보다 일찍 반납해도 연체료가 없다")
    void noFeeWhenReturnedEarly() {
        assertEquals(0, calculator.calculate(due, due.minusDays(2)));
    }

    @Test
    @DisplayName("유예 기간 마지막 날(3일 연체)까지는 연체료가 없다")
    void noFeeWithinGracePeriod() {
        assertEquals(0, calculator.calculate(due, due.plusDays(3)));
    }

    @Test
    @DisplayName("5일 연체는 유예 3일을 뺀 2일치만 부과한다")
    void chargesOnlyDaysBeyondGrace() {
        assertEquals(1000, calculator.calculate(due, due.plusDays(5)));
    }

    @Test
    @DisplayName("연체료는 상한을 넘지 않는다")
    void feeIsCapped() {
        assertEquals(FeeCalculator.MAX_FEE, calculator.calculate(due, due.plusDays(365)));
    }

    @Test
    @DisplayName("날짜가 없으면 거부한다")
    void rejectsNullDates() {
        assertThrows(IllegalArgumentException.class, () -> calculator.calculate(null, due));
        assertThrows(IllegalArgumentException.class, () -> calculator.calculate(due, null));
    }
}
