package dev.rgal.brackety.auth.lockout;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.common.crypto.Sha256;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

class LoginLockoutTest extends AuthIntegrationTest {

    private static final String IP = "203.0.113.10";
    private static final String ANA = "ana@example.test";

    @Autowired
    AuthService auth;

    @Autowired
    LoginAttemptPurge purge;

    @BeforeEach
    void registerAna() {
        auth.register(registration(ANA));
    }

    @Test
    void fourEmailFailuresDoNotLockAndFiveDo() {
        assertThat(failFromManyIps(ANA, 4)).containsOnly(HttpStatus.UNAUTHORIZED);
        assertThat(loginStatus(ANA, "wrong-password", "198.51.100.200")).isEqualTo(HttpStatus.UNAUTHORIZED);

        assertThat(loginStatus(ANA, PASSWORD, IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
    }

    @Test
    void emailLockLastsFifteenMinutes() {
        failFromManyIps(ANA, 5);

        clock.advance(Duration.ofMinutes(15).minusSeconds(1));
        assertThat(loginStatus(ANA, PASSWORD, IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        clock.advance(Duration.ofSeconds(1));
        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void failuresMoreThanFifteenMinutesApartDoNotAddUp() {
        failFromManyIps(ANA, 4);
        clock.advance(Duration.ofMinutes(15).plusSeconds(1));

        failFromManyIps(ANA, 4);

        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void successfulLoginResetsTheEmailCounter() {
        failFromManyIps(ANA, 4);
        auth.login(ANA, PASSWORD, IP);

        failFromManyIps(ANA, 4);

        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void unknownEmailsLockAndGetALockIdToo() {
        failFromManyIps("nobody@example.test", 5);

        var locked = catchAuth(() -> auth.login("nobody@example.test", "wrong-password", IP));

        assertThat(locked.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        assertThat(lockIdOf(locked)).matches("L-[2-9A-HJKMNP-Z]{6}");
    }

    @Test
    void lockIdIsStoredWithTheAccountIdAndNeverTheEmail() {
        failFromManyIps(ANA, 5);

        var lockId = lockIdOf(catchAuth(() -> auth.login(ANA, PASSWORD, IP)));

        var row = jdbc.sql("select attempt_key, account_id, ip from login_attempt where lock_id = ?")
                .param(lockId)
                .query((rs, n) -> List.of(
                        rs.getString("attempt_key"),
                        String.valueOf(rs.getObject("account_id")),
                        "" + rs.getString("ip")))
                .single();
        var accountId = jdbc.sql("select id from account").query(String.class).single();
        assertThat(row).containsExactly("email:" + Sha256.hex(ANA), accountId, "null");
        assertThat(jdbc.sql("select count(*) from login_attempt where attempt_key like '%ana%'")
                        .query(Integer.class)
                        .single())
                .isZero();
    }

    @Test
    void ipRowsKeepTheIpInClear() {
        loginStatus(ANA, "wrong-password", IP);

        assertThat(jdbc.sql("select ip from login_attempt where attempt_key = ?")
                        .param("ip:" + Sha256.hex(IP))
                        .query(String.class)
                        .single())
                .isEqualTo(IP);
    }

    @Test
    void twentyNineIpFailuresDoNotLockAndThirtyDo() {
        failFromOneIp(29);
        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();

        failFromOneIp(1);

        var locked = catchAuth(() -> auth.login(ANA, PASSWORD, IP));
        assertThat(locked.getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        assertThat(lockIdOf(locked)).startsWith("L-");
        assertThat(auth.login(ANA, PASSWORD, "203.0.113.99").accessToken()).isNotBlank();
    }

    @Test
    void fiveUsersFailingBehindOneIpDoNotLockTheSixth() {
        failFromOneIp(5);

        assertThat(auth.login(ANA, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void purgeDeletesRowsOnlyOnceTheirWindowAndLockAreOver() {
        failFromManyIps(ANA, 5);
        loginStatus("other@example.test", "wrong-password", IP);
        var rows = count("login_attempt");

        clock.advance(Duration.ofMinutes(15));
        purge.purge();
        assertThat(count("login_attempt")).isEqualTo(rows);

        clock.advance(Duration.ofSeconds(1));
        purge.purge();
        assertThat(count("login_attempt")).isZero();
    }

    @Test
    void purgeKeepsRowsStillInsideTheirWindow() {
        failFromManyIps(ANA, 5);
        clock.advance(Duration.ofMinutes(10));
        loginStatus("other@example.test", "wrong-password", IP);

        clock.advance(Duration.ofMinutes(10));
        purge.purge();

        assertThat(jdbc.sql("select attempt_key from login_attempt")
                        .query(String.class)
                        .list())
                .containsExactlyInAnyOrder("email:" + Sha256.hex("other@example.test"), "ip:" + Sha256.hex(IP));
    }

    // Each failure from a different IP, so only the email counter adds up.
    private List<HttpStatus> failFromManyIps(String email, int times) {
        var statuses = new ArrayList<HttpStatus>();
        for (int i = 1; i <= times; i++) {
            statuses.add(loginStatus(email, "wrong-password", "198.51.100." + i));
        }
        return statuses;
    }

    // Each failure on a different email, so only the IP counter adds up.
    private void failFromOneIp(int times) {
        for (int i = 1; i <= times; i++) {
            loginStatus("guess" + i + "@example.test", "wrong-password", IP);
        }
    }

    private HttpStatus loginStatus(String email, String password, String ip) {
        return HttpStatus.valueOf(
                catchAuth(() -> auth.login(email, password, ip)).getStatusCode().value());
    }

    private static String lockIdOf(AuthException e) {
        return (String) e.getBody().getProperties().get("lockId");
    }

    private static AuthException catchAuth(Runnable call) {
        try {
            call.run();
        } catch (AuthException e) {
            return e;
        }
        throw new AssertionError("Expected an AuthException");
    }
}
