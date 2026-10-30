package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.groups.Tuple.tuple;

import dev.rgal.brackety.auth.account.AccountRepository;
import dev.rgal.brackety.auth.account.Consent;
import dev.rgal.brackety.auth.account.ConsentRepository;
import dev.rgal.brackety.auth.account.ProfileRepository;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import java.time.LocalDate;
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

    private static AuthException catchAuth(Runnable call) {
        try {
            call.run();
        } catch (AuthException e) {
            return e;
        }
        throw new AssertionError("Expected an AuthException");
    }
}
