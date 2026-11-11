package practice.loan;

import java.time.LocalDate;

/**
 * 대출 연장 정책. <b>아직 구현되지 않았다.</b>
 *
 * <p>규정:
 * <ul>
 *   <li>한 건의 대출은 최대 {@value #MAX_RENEWALS}회까지 연장할 수 있다.</li>
 *   <li>이미 연체 중이면(오늘이 반납 예정일을 지났으면) 연장할 수 없다.</li>
 *   <li>정지된 회원은 연장할 수 없다.</li>
 *   <li>다른 회원이 해당 도서를 예약 중이면 연장할 수 없다.</li>
 *   <li>연장에 성공하면 새 반납 예정일은 <b>기존 반납 예정일 기준</b> +{@value #EXTENSION_DAYS}일이다.
 *       오늘 날짜 기준이 아니다.</li>
 * </ul>
 */
public class RenewalPolicy {

    public static final int MAX_RENEWALS = 2;
    public static final int EXTENSION_DAYS = 14;

    /**
     * 연장이 가능한지 판단한다.
     *
     * @param member          연장을 요청한 회원
     * @param currentDueDate  현재 반납 예정일
     * @param today           오늘 날짜
     * @param renewalCount    지금까지 연장한 횟수
     * @param reservedByOther 다른 회원의 예약 존재 여부
     * @return 연장 가능하면 true
     */
    public boolean canRenew(Member member, LocalDate currentDueDate, LocalDate today,
                            int renewalCount, boolean reservedByOther) {
        throw new UnsupportedOperationException("아직 구현되지 않았다");
    }

    /**
     * 연장 후의 새 반납 예정일을 계산한다.
     *
     * @param currentDueDate 현재 반납 예정일
     * @return 새 반납 예정일
     */
    public LocalDate renew(LocalDate currentDueDate) {
        throw new UnsupportedOperationException("아직 구현되지 않았다");
    }
}
