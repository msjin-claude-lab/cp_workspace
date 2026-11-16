package practice.loan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@link AdminGate}의 보안 요구사항을 옮긴 테스트다(/security-review 과제 4번).
 *
 * <p>기대값은 구현이 아니라 요구사항에서 왔다: 비밀은 코드에 두지 않는다, 비밀과 개인정보는
 * 로그·감사 기록에 남기지 않는다, 사용자 입력을 SQL 문자열에 이어 붙이지 않는다.
 */
class AdminGateTest {

    private static final String SECRET = "test-secret-값";
    /** 이전 버전 소스에 하드코딩돼 있던 값. 이제 아무 권한도 주면 안 된다. */
    private static final String LEAKED_OLD_TOKEN = "cp-admin-2026!";

    private final Member member = new Member("M-001", "홍길동", "hong@example.com");

    private final List<LogRecord> records = new ArrayList<>();
    private final Logger logger = Logger.getLogger(AdminGate.class.getName());
    private final Handler capture = new Handler() {
        @Override
        public void publish(LogRecord record) {
            records.add(record);
        }

        @Override
        public void flush() {
        }

        @Override
        public void close() {
        }
    };
    private Level previousLevel;

    @BeforeEach
    void captureLogs() {
        previousLevel = logger.getLevel();
        logger.setLevel(Level.ALL);
        logger.addHandler(capture);
    }

    @AfterEach
    void releaseLogs() {
        logger.removeHandler(capture);
        logger.setLevel(previousLevel);
    }

    private String allLogText() {
        StringBuilder sb = new StringBuilder();
        for (LogRecord r : records) {
            sb.append(r.getMessage()).append('\n');
        }
        return sb.toString();
    }

    // --- 인증 ---------------------------------------------------------------

    @Test
    @DisplayName("설정된 토큰과 같으면 관리자로 인증한다")
    void acceptsConfiguredToken() {
        assertTrue(new AdminGate(SECRET).authenticate(member, SECRET));
    }

    @Test
    @DisplayName("다른 토큰이나 null 토큰은 거부한다")
    void rejectsWrongOrNullToken() {
        AdminGate gate = new AdminGate(SECRET);
        assertFalse(gate.authenticate(member, "wrong"));
        assertFalse(gate.authenticate(member, null));
    }

    @Test
    @DisplayName("예전에 코드에 박혀 있던 토큰은 더 이상 통하지 않는다")
    void oldHardcodedTokenGivesNoAccess() {
        assertFalse(new AdminGate(SECRET).authenticate(member, LEAKED_OLD_TOKEN));
        assertFalse(new AdminGate(null).authenticate(member, LEAKED_OLD_TOKEN));
    }

    @Test
    @DisplayName("토큰이 설정되지 않았으면 누구도 인증하지 않는다(빈 문자열 포함)")
    void failsClosedWithoutConfiguredToken() {
        assertFalse(new AdminGate(null).authenticate(member, null));
        assertFalse(new AdminGate("").authenticate(member, ""));
    }

    @Test
    @DisplayName("회원이 null이면 거부한다")
    void rejectsNullMember() {
        assertThrows(IllegalArgumentException.class, () -> new AdminGate(SECRET).authenticate(null, SECRET));
    }

    // --- 로그 ---------------------------------------------------------------

    @Test
    @DisplayName("성공·실패 어느 쪽에서도 토큰을 로그에 남기지 않는다")
    void neverLogsTokens() {
        AdminGate gate = new AdminGate(SECRET);
        gate.authenticate(member, SECRET);
        gate.authenticate(member, "typo-of-secret");

        String logs = allLogText();
        assertFalse(logs.contains(SECRET), logs);
        assertFalse(logs.contains("typo-of-secret"), logs);
    }

    @Test
    @DisplayName("로그에는 회원 id만 남기고 이름·이메일은 남기지 않는다")
    void logsIdButNoPersonalData() {
        AdminGate gate = new AdminGate(SECRET);
        gate.authenticate(member, SECRET);
        gate.authenticate(member, "wrong");

        String logs = allLogText();
        assertTrue(logs.contains("M-001"), logs);
        assertFalse(logs.contains("홍길동"), logs);
        assertFalse(logs.contains("hong@example.com"), logs);
    }

    // --- 감사 기록 -----------------------------------------------------------

    @Test
    @DisplayName("감사 기록은 회원 id와 행위만 담고 토큰·이메일은 담지 않는다")
    void auditLineHasNoSecretOrEmail() {
        String line = new AdminGate(SECRET).auditLine(member, "회원 정지");

        assertEquals("M-001 | 회원 정지", line);
    }

    // --- 회원 검색 쿼리 -------------------------------------------------------

    @Test
    @DisplayName("검색 쿼리는 자리표시자를 쓰고 검색어를 이어 붙이지 않는다")
    void memberQueryUsesPlaceholder() {
        assertEquals("SELECT * FROM member WHERE name LIKE ? ESCAPE '\\'", new AdminGate(SECRET).buildMemberQuery());
    }

    @Test
    @DisplayName("검색어는 LIKE 와일드카드를 이스케이프한 바인딩 값으로 만든다")
    void searchParamEscapesWildcards() {
        AdminGate gate = new AdminGate(SECRET);

        assertEquals("%홍%", gate.memberSearchParam("홍"));
        assertEquals("%' OR '1'='1%", gate.memberSearchParam("' OR '1'='1"));
        assertEquals("%100\\%\\_\\\\%", gate.memberSearchParam("100%_\\"));
    }

    @Test
    @DisplayName("검색어가 null이면 거부한다")
    void rejectsNullKeyword() {
        assertThrows(IllegalArgumentException.class, () -> new AdminGate(SECRET).memberSearchParam(null));
    }
}
