package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.groups.Tuple.tuple;

import dev.rgal.brackety.auth.dto.RegisterRequest;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

class AuthServiceTest extends AuthIntegrationTest {

    private static final String IP = "203.0.113.10";

    @Autowired
    AuthService auth;

    @Autowired
    AccountRepository accounts;

    @Autowired
    ProfileRepository profiles;

    @Autowired
    ConsentRepository consents;

    @Test
    void registersAnUnverifiedAccountWithItsProfileAndConsents() {
        auth.register(registration("  Ana@Example.TEST "));

        var account = accounts.findByEmail("ana@example.test").orElseThrow();
        assertThat(account.isEmailVerified()).isFalse();
        assertThat(account.isActive()).isTrue();
        assertThat(profiles.findByAccountId(account.getId())).singleElement().satisfies(p -> {
            assertThat(p.getType()).isEqualTo(ProfileType.CLUB);
            assertThat(p.isValidated()).isFalse();
        });
        assertThat(consents.findByAccountId(account.getId()))
                .extracting(Consent::getDocument, Consent::getVersion, Consent::getAcceptedAt)
                .containsExactlyInAnyOrder(
                        tuple(Consent.Document.TERMS, "2027-01", AuthTestConfig.START),
                        tuple(Consent.Document.PRIVACY, "2027-02", AuthTestConfig.START));
    }

    @Test
    void storesAnArgon2idHashNeverThePassword() {
        auth.register(registration("ana@example.test"));

        var hash = accounts.findByEmail("ana@example.test").orElseThrow().getPasswordHash();
        assertThat(hash).startsWith("$argon2id$").doesNotContain(PASSWORD);
    }

    @Test
    void rejectsUnder14ByTheClockDay() {
        // The clock says 2027-03-10: born 2013-03-11 is one day short of 14.
        assertThatThrownBy(() -> auth.register(registration("kid@example.test", LocalDate.of(2013, 3, 11))))
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThat(count("account")).isZero();

        auth.register(registration("teen@example.test", LocalDate.of(2013, 3, 10)));
        assertThat(count("account")).isOne();
    }

    @Test
    void duplicateEmailIsAcceptedSilentlyAndChangesNothing() {
        auth.register(registration("ana@example.test"));
        var duplicate = new RegisterRequest(
                "ANA@example.test", "another-password", LocalDate.of(1980, 1, 1), ProfileType.STUDENT, "v", "v", "en");

        auth.register(duplicate);

        assertThat(count("account")).isOne();
        assertThat(count("profile")).isOne();
        assertThat(count("consent")).isEqualTo(2);
        assertThat(auth.login("ana@example.test", PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void logsInCaseInsensitively() {
        auth.register(registration("ana@example.test"));

        var session = auth.login("Ana@Example.test", PASSWORD, IP);

        assertThat(session.accessToken()).isNotBlank();
        assertThat(session.refreshToken()).isNotBlank();
        assertThat(session.expiresIn()).isEqualTo(900);
    }

    @Test
    void wrongPasswordAndUnknownEmailFailTheSameWay() {
        auth.register(registration("ana@example.test"));

        var wrongPassword = catchAuth(() -> auth.login("ana@example.test", "wrong-password", IP));
        var unknownEmail = catchAuth(() -> auth.login("nobody@example.test", PASSWORD, IP));

        assertThat(wrongPassword.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(unknownEmail.getStatusCode()).isEqualTo(wrongPassword.getStatusCode());
        assertThat(unknownEmail.getBody().getDetail())
                .isEqualTo(wrongPassword.getBody().getDetail());
    }

    @Test
    void locksTheAccountAfterFiveFailuresForFifteenMinutes() {
        auth.register(registration("ana@example.test"));
        assertThat(failTimes("ana@example.test", 5)).containsOnly(HttpStatus.UNAUTHORIZED);

        assertThat(loginStatus("ana@example.test", PASSWORD, IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        clock.advance(Duration.ofMinutes(15).minusSeconds(1));
        assertThat(loginStatus("ana@example.test", PASSWORD, IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        clock.advance(Duration.ofSeconds(1));
        assertThat(auth.login("ana@example.test", PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void unknownEmailsLockLikeRealOnes() {
        failTimes("nobody@example.test", 5);

        assertThat(loginStatus("nobody@example.test", "wrong-password", IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
    }

    @Test
    void successfulLoginResetsTheAccountCounter() {
        auth.register(registration("ana@example.test"));
        failTimes("ana@example.test", 4);
        auth.login("ana@example.test", PASSWORD, IP);

        failTimes("ana@example.test", 4);

        assertThat(auth.login("ana@example.test", PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void locksTheIpAfterFiveFailuresOnAnyAccounts() {
        auth.register(registration("ana@example.test"));
        for (int i = 1; i <= 5; i++) {
            loginStatus("guess" + i + "@example.test", "wrong-password", IP);
        }

        assertThat(loginStatus("ana@example.test", PASSWORD, IP)).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        assertThat(auth.login("ana@example.test", PASSWORD, "203.0.113.99").accessToken())
                .isNotBlank();
    }

    // Each failure from a different IP, so only the account counter adds up.
    private List<HttpStatus> failTimes(String email, int times) {
        var statuses = new ArrayList<HttpStatus>();
        for (int i = 1; i <= times; i++) {
            statuses.add(loginStatus(email, "wrong-password", "198.51.100." + i));
        }
        return statuses;
    }

    private HttpStatus loginStatus(String email, String password, String ip) {
        return HttpStatus.valueOf(
                catchAuth(() -> auth.login(email, password, ip)).getStatusCode().value());
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
