package dev.rgal.brackety.auth.google;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.session.SessionService;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

class GoogleSignInTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final LocalDate ADULT = LocalDate.of(1990, 5, 20);

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    FakeGoogle google;

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Test
    void aNewGoogleUserIsAskedForTheRegistrationDetailsFirst() {
        var result = googleSignIn.signIn(google.idToken("sub-ana", "Ana@Example.test"), null);

        assertThat(result.session()).isNull();
        assertThat(result.registrationEmail()).isEqualTo(ANA);
        assertThat(count("account")).isZero();
    }

    @Test
    void registeringWithGoogleCreatesAVerifiedAccountWithoutPassword() {
        var result = googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));

        assertThat(result.session().accessToken()).isNotBlank();
        assertThat(result.session().emailVerified()).isTrue();
        assertThat(result.replacedUnverifiedAccount()).isFalse();
        assertThat(count("account where email = 'ana@example.test' and email_verified and password_hash is null"
                        + " and locale = 'en' and birth_date = '1990-05-20'"))
                .isOne();
        assertThat(count("profile where type = 'STUDENT'")).isOne();
        assertThat(count("consent where document = 'TERMS' and version = '2027-01'"))
                .isOne();
        assertThat(count("consent where document = 'PRIVACY' and version = '2027-02'"))
                .isOne();
        assertThat(count("identity where provider = 'GOOGLE' and subject = 'sub-ana'"
                        + " and provider_email = 'ana@example.test'"))
                .isOne();
        assertThat(emails.sent()).isEmpty();
    }

    @Test
    void theNextSignInFindsTheIdentityBySubjectNotByEmail() {
        googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));

        // Same person after changing the address in Google: still the same account.
        var again = googleSignIn.signIn(google.idToken("sub-ana", "ana.new@example.test"), null);

        assertThat(again.session().accessToken()).isNotBlank();
        assertThat(count("account")).isOne();
        // Another Google user that now owns the address is not let in.
        assertConflict(() -> googleSignIn.signIn(google.idToken("sub-other", ANA), details(ADULT)), "ACCOUNT_EXISTS");
    }

    @Test
    void under14CannotRegisterWithGoogle() {
        var underage = LocalDate.of(2013, 3, 11);

        assertThatThrownBy(() -> googleSignIn.signIn(google.idToken("sub-kid", "kid@example.test"), details(underage)))
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThat(count("account")).isZero();
    }

    @Test
    void anUnverifiedPasswordAccountIsReplacedWithItsSessions() {
        auth.register(registration(ANA));
        var oldId = accountId();
        var oldSession = auth.login(ANA, PASSWORD, "203.0.113.10");

        var result = googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));

        assertThat(result.replacedUnverifiedAccount()).isTrue();
        assertThat(result.session().emailVerified()).isTrue();
        assertThat(accountId()).isNotEqualTo(oldId);
        assertThat(count("account where password_hash is null and email_verified"))
                .isOne();
        assertThat(count("refresh_token where account_id = '" + oldId + "'")).isZero();
        assertThat(count("profile")).isOne();
        assertThat(count("email_token")).isZero();
        assertThatThrownBy(() -> sessions.refresh(oldSession.refreshToken())).isInstanceOf(AuthException.class);
    }

    @Test
    void theUnverifiedAccountIsKeptUntilTheGoogleRegistrationIsCompleted() {
        auth.register(registration(ANA));
        var id = accountId();

        var result = googleSignIn.signIn(google.idToken("sub-ana", ANA), null);

        assertThat(result.registrationEmail()).isEqualTo(ANA);
        assertThat(accountId()).isEqualTo(id);
    }

    @Test
    void anUnderageGoogleRegistrationLeavesTheUnverifiedAccountAlone() {
        auth.register(registration(ANA));
        var id = accountId();

        assertThatThrownBy(
                        () -> googleSignIn.signIn(google.idToken("sub-ana", ANA), details(LocalDate.of(2013, 3, 11))))
                .isInstanceOf(AuthException.class);

        assertThat(accountId()).isEqualTo(id);
    }

    @Test
    void aVerifiedAccountWithTheSameEmailIsNeverMerged() {
        auth.register(registration(ANA));
        jdbc.sql("update account set email_verified = true").update();

        assertConflict(() -> googleSignIn.signIn(google.idToken("sub-ana", ANA), null), "ACCOUNT_EXISTS");
        assertConflict(() -> googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT)), "ACCOUNT_EXISTS");
        assertThat(count("identity")).isZero();
        assertThat(count("account where password_hash is not null")).isOne();
    }

    @Test
    void aDeletedAccountGetsTheGeneric401() {
        googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));
        jdbc.sql("update account set status = 'DELETED'").update();

        assertUnauthorized(() -> googleSignIn.signIn(google.idToken("sub-ana", ANA), null));
        // Also when found by email, with another Google user.
        assertUnauthorized(() -> googleSignIn.signIn(google.idToken("sub-other", ANA), details(ADULT)));
    }

    private UUID accountId() {
        return jdbc.sql("select id from account").query(UUID.class).single();
    }

    private static void assertConflict(Runnable call, String code) {
        assertThatThrownBy(call::run).isInstanceOfSatisfying(AuthException.class, e -> {
            assertThat(e.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
            assertThat(e.getBody().getProperties()).containsEntry("code", code);
        });
    }

    private static void assertUnauthorized(Runnable call) {
        assertThatThrownBy(call::run)
                .isInstanceOfSatisfying(
                        AuthException.class, e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));
    }
}
