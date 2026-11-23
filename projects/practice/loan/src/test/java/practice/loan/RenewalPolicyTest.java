package practice.loan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 연장 규정({@link RenewalPolicy} javadoc)을 그대로 옮긴 테스트다.
 * 기대값은 모두 javadoc 규정에서 나온다. null 처리만 규정에 없어 {@link FeeCalculator}의 방식을 따른다.
 */
class RenewalPolicyTest {

    private final RenewalPolicy policy = new RenewalPolicy();
    private final Member member = new Member("M1", "홍길동", "hong@example.com");
    private final LocalDate due = LocalDate.of(2026, 3, 10);
    private final LocalDate beforeDue = due.minusDays(2);

    @Test
    @DisplayName("제약이 없으면 연장할 수 있다")
    void canRenewWhenNoRestriction() {
        assertTrue(policy.canRenew(member, due, beforeDue, 0, false));
    }

    @Test
    @DisplayName("최대 연장 횟수(2회)를 채우면 더 연장할 수 없다")
    void cannotRenewAtMaxRenewals() {
        assertFalse(policy.canRenew(member, due, beforeDue, 2, false));
    }

    @Test
    @DisplayName("한 번 연장한 뒤에는 한 번 더 연장할 수 있다")
    void canRenewOnceMoreBelowMax() {
        assertTrue(policy.canRenew(member, due, beforeDue, 1, false));
    }

    @Test
    @DisplayName("반납 예정일을 지나 연체 중이면 연장할 수 없다")
    void cannotRenewWhenOverdue() {
        assertFalse(policy.canRenew(member, due, due.plusDays(1), 0, false));
    }

    @Test
    @DisplayName("반납 예정일 당일은 아직 연체가 아니므로 연장할 수 있다")
    void canRenewOnDueDate() {
        assertTrue(policy.canRenew(member, due, due, 0, false));
    }

    @Test
    @DisplayName("정지된 회원은 연장할 수 없다")
    void cannotRenewWhenMemberSuspended() {
        member.setSuspended(true);
        assertFalse(policy.canRenew(member, due, beforeDue, 0, false));
    }

    @Test
    @DisplayName("다른 회원이 예약 중이면 연장할 수 없다")
    void cannotRenewWhenReservedByOther() {
        assertFalse(policy.canRenew(member, due, beforeDue, 0, true));
    }

    @Test
    @DisplayName("새 반납 예정일은 기존 반납 예정일 기준 +14일이다")
    void renewExtendsFromCurrentDueDate() {
        assertEquals(LocalDate.of(2026, 3, 24), policy.renew(due));
    }

    @Test
    @DisplayName("연장 가능 여부 판단에 회원·날짜가 없으면 거부한다")
    void canRenewRejectsNullArguments() {
        assertThrows(IllegalArgumentException.class, () -> policy.canRenew(null, due, beforeDue, 0, false));
        assertThrows(IllegalArgumentException.class, () -> policy.canRenew(member, null, beforeDue, 0, false));
        assertThrows(IllegalArgumentException.class, () -> policy.canRenew(member, due, null, 0, false));
    }

    @Test
    @DisplayName("연장할 반납 예정일이 없으면 거부한다")
    void renewRejectsNullDueDate() {
        assertThrows(IllegalArgumentException.class, () -> policy.renew(null));
    }
}
