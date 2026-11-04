package dev.rgal.brackety.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.groups.Tuple.tuple;

import dev.rgal.brackety.auth.account.AccountRepository;
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

    @Test
    void registersAnUnverifiedAccountWithItsProfileAndConsents() {
        auth.register(registration("  Ana@Example.TEST "));

        var account = accounts.findByEmail("ana@example.test").orElseThrow();
        assertThat(account.isEmailVerified()).isFalse();
        assertThat(account.isActive()).isTrue();
        assertThat(account.getBirthDate()).isNull();
        assertThat(jdbc.sql("select type, validated, organization_name, tax_id from profile where account_id = ?")
                        .param(account.getId())
                        .query((rs, n) -> tuple(
                                rs.getString("type"),
                                rs.getBoolean("validated"),
                                rs.getString("organization_name"),
                                rs.getString("tax_id")))
                        .list())
                .containsExactly(tuple(ProfileType.CLUB.name(), false, "Club Ficticio", "G12345674"));
        assertThat(jdbc.sql("select document, version, accepted_at from consent where account_id = ?")
                        .param(account.getId())
                        .query((rs, n) -> tuple(
                                rs.getString("document"),
                                rs.getString("version"),
                                rs.getTimestamp("accepted_at").toInstant()))
                        .list())
                .containsExactlyInAnyOrder(
                        tuple("TERMS", TERMS_VERSION, AuthTestConfig.START),
                        tuple("PRIVACY", PRIVACY_VERSION, AuthTestConfig.START),
                        tuple("ORGANIZER_DECLARATION", TERMS_VERSION, AuthTestConfig.START));
    }

    @Test
    void aStudentHasABirthDateAndNoOrganization() {
        auth.register(registration("ana@example.test", ADULT));

        assertThat(accounts.findByEmail("ana@example.test").orElseThrow().getBirthDate())
                .isEqualTo(ADULT);
        assertThat(count("profile where organization_name is null and tax_id is null"))
                .isOne();
        assertThat(count("consent")).isEqualTo(2);
    }

    @Test
    void severalAccountsCanManageTheSameOrganization() {
        auth.register(registration("ana@example.test"));
        auth.register(registration("bea@example.test", ProfileType.EXTERNAL_ENTITY, "en"));

        assertThat(count("profile where tax_id = 'G12345674'")).isEqualTo(2);
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
                "ANA@example.test",
                "another-password",
                ProfileType.STUDENT,
                LocalDate.of(1980, 1, 1),
                null,
                null,
                TERMS_VERSION,
                PRIVACY_VERSION,
                "en");

        auth.register(duplicate);

        assertThat(count("account")).isOne();
        assertThat(count("profile")).isOne();
        assertThat(count("consent")).isEqualTo(3);
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
