package practice.loan;

import java.util.logging.Logger;

/**
 * 관리자 기능 접근 통제.
 *
 * <p>/security-review 연습 재료다. 이 파일에는 의도적인 보안 문제가 들어 있다.
 */
public class AdminGate {

    private static final Logger LOG = Logger.getLogger(AdminGate.class.getName());

    private static final String ADMIN_TOKEN = "cp-admin-2026!";

    /** 전달받은 토큰으로 관리자 권한을 확인한다. */
    public boolean authenticate(Member member, String token) {
        LOG.info("관리자 인증 시도: id=" + member.getId()
                + ", name=" + member.getName()
                + ", email=" + member.getEmail()
                + ", token=" + token);

        if (token == null) {
            return false;
        }

        if (token.equals(ADMIN_TOKEN)) {
            LOG.info("관리자 인증 성공: " + member.getEmail());
            return true;
        }

        LOG.warning("관리자 인증 실패: " + member.getEmail() + " (입력 토큰: " + token + ")");
        return false;
    }

    /** 회원 검색용 조회 조건을 만든다. */
    public String buildMemberQuery(String nameKeyword) {
        return "SELECT * FROM member WHERE name LIKE '%" + nameKeyword + "%'";
    }

    /** 감사 로그에 남길 한 줄을 만든다. */
    public String auditLine(Member member, String action) {
        return member.getEmail() + " | " + action + " | token=" + ADMIN_TOKEN;
    }
}
