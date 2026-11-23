package practice.loan;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.logging.Logger;

/**
 * 관리자 기능 접근 통제.
 *
 * <p>/security-review 연습 재료였다(과제 4번). 아래 결함을 고쳤다.
 * <ul>
 *   <li>관리자 토큰을 소스에 하드코딩하던 것 → 생성자로 받거나 환경변수에서 읽는다</li>
 *   <li>입력 토큰·이름·이메일을 로그에 남기던 것 → 회원 id만 남긴다</li>
 *   <li>감사 기록에 실제 관리자 토큰을 넣던 것 → 회원 id와 행위만 담는다</li>
 *   <li>검색어를 SQL에 이어 붙이던 것 → 자리표시자 쿼리와 바인딩 값을 따로 만든다</li>
 * </ul>
 */
public class AdminGate {

    private static final Logger LOG = Logger.getLogger(AdminGate.class.getName());

    /** 관리자 토큰을 읽어 올 환경변수 이름. */
    public static final String TOKEN_ENV = "LOAN_ADMIN_TOKEN";

    private static final String MEMBER_SEARCH_SQL = "SELECT * FROM member WHERE name LIKE ? ESCAPE '!'";

    private final byte[] adminToken;

    /** 관리자 토큰을 환경변수 {@value #TOKEN_ENV}에서 읽는다. */
    public AdminGate() {
        this(System.getenv(TOKEN_ENV));
    }

    /**
     * @param adminToken 관리자 토큰. null이나 빈 문자열이면 아무도 인증하지 않는다(안전한 쪽으로 실패).
     */
    public AdminGate(String adminToken) {
        this.adminToken = (adminToken == null || adminToken.isEmpty())
                ? null
                : adminToken.getBytes(StandardCharsets.UTF_8);
    }

    /** 전달받은 토큰으로 관리자 권한을 확인한다. 로그에는 회원 id만 남긴다. */
    public boolean authenticate(Member member, String token) {
        if (member == null) {
            throw new IllegalArgumentException("member는 null일 수 없다");
        }
        LOG.info("관리자 인증 시도: id=" + member.getId());

        if (adminToken == null || token == null) {
            LOG.warning("관리자 인증 실패: id=" + member.getId());
            return false;
        }

        // 상수 시간 비교 — 응답 시간으로 토큰을 한 글자씩 추측하지 못하게 한다
        if (MessageDigest.isEqual(adminToken, token.getBytes(StandardCharsets.UTF_8))) {
            LOG.info("관리자 인증 성공: id=" + member.getId());
            return true;
        }

        LOG.warning("관리자 인증 실패: id=" + member.getId());
        return false;
    }

    /**
     * 회원 검색 쿼리. 검색어는 이어 붙이지 않고 {@code ?} 자리에 바인딩한다.
     *
     * <pre>{@code
     * PreparedStatement ps = conn.prepareStatement(gate.buildMemberQuery());
     * ps.setString(1, gate.memberSearchParam(keyword));
     * }</pre>
     */
    public String buildMemberQuery() {
        return MEMBER_SEARCH_SQL;
    }

    /** 검색어를 LIKE 바인딩 값으로 만든다. {@code ! % _}는 문자 그대로 찾도록 {@code !}로 이스케이프한다(ESCAPE '!').
     * 백슬래시는 MySQL/MariaDB 기본 설정에서 문자열 이스케이프라 ESCAPE 문자로 쓰지 않는다. */
    public String memberSearchParam(String nameKeyword) {
        if (nameKeyword == null) {
            throw new IllegalArgumentException("nameKeyword는 null일 수 없다");
        }
        String escaped = nameKeyword
                .replace("!", "!!")
                .replace("%", "!%")
                .replace("_", "!_");
        return "%" + escaped + "%";
    }

    /** 감사 로그에 남길 한 줄을 만든다. 비밀과 개인정보는 넣지 않는다. */
    public String auditLine(Member member, String action) {
        return member.getId() + " | " + action;
    }
}
