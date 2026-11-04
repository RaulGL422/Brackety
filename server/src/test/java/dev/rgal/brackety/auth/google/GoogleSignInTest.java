package dev.rgal.brackety.auth.google;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.session.SessionService;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

class GoogleSignInTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String BEA = "bea@example.test";

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
        assertThat(count("consent where document = 'TERMS' and version = '2026-11-04'"))
                .isOne();
        assertThat(count("consent where document = 'PRIVACY' and version = '2026-11-04'"))
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
    void anOrganizerRegistersWithGoogleWithoutABirthDate() {
        googleSignIn.signIn(google.idToken("sub-ana", ANA), organizerDetails(ProfileType.CLUB, ORGANIZATION));

        assertThat(count("account where birth_date is null and email_verified")).isOne();
        assertThat(count("profile where type = 'CLUB' and tax_id = 'G12345674'"))
                .isOne();
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
    void anUnverifiedPasswordAccountIsReplacedWithEverythingItHad() {
        auth.register(registration(BEA));
        var bea = idOf(BEA);
        var beaSession = auth.login(BEA, PASSWORD, "203.0.113.10");
        auth.register(registration(ANA));
        var oldId = idOf(ANA);
        var oldSession = auth.login(ANA, PASSWORD, "203.0.113.10");
        // Not possible through the API any more (EMAIL_NOT_VERIFIED), but older or seeded data may have it.
        jdbc.sql("insert into identity (id, account_id, provider, subject, provider_email, created_at)"
                        + " values (gen_random_uuid(), ?, 'GOOGLE', 'sub-old', 'old@example.test', now())")
                .param(oldId)
                .update();

        var result = googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));

        assertThat(result.replacedUnverifiedAccount()).isTrue();
        assertThat(result.session().emailVerified()).isTrue();
        var newId = idOf(ANA);
        assertThat(newId).isNotEqualTo(oldId);
        assertThat(count("account where id = '" + newId + "' and password_hash is null and email_verified"))
                .isOne();
        for (var table : new String[] {"refresh_token", "profile", "consent", "email_token", "identity"}) {
            assertThat(count(table + " where account_id = '" + oldId + "'"))
                    .as(table)
                    .isZero();
        }
        assertThat(count("identity where subject = 'sub-old'")).isZero();
        assertThatThrownBy(() -> sessions.refresh(oldSession.refreshToken())).isInstanceOf(AuthException.class);

        assertThat(count("profile where account_id = '" + bea + "'")).isOne();
        assertThat(count("consent where account_id = '" + bea + "'")).isEqualTo(3);
        assertThat(count("email_token where account_id = '" + bea + "'")).isOne();
        assertThat(sessions.refresh(beaSession.refreshToken()).accessToken()).isNotBlank();
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
    void aDeletedAccountIsOfferedTheRestoreAndNeverASecondAccount() {
        googleSignIn.signIn(google.idToken("sub-ana", ANA), details(ADULT));
        jdbc.sql("update account set status = 'DELETED', deleted_at = ?")
                .param(Timestamp.from(clock.instant()))
                .update();

        assertThatThrownBy(() -> googleSignIn.signIn(google.idToken("sub-ana", ANA), null))
                .isInstanceOfSatisfying(AuthException.class, e -> {
                    assertThat(e.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
                    assertThat(e.getBody().getProperties())
                            .containsEntry("code", "ACCOUNT_PENDING_DELETION")
                            .containsEntry("deletesOn", "2027-04-09")
                            .containsKey("restoreToken");
                });
        // Found by email, with another Google user: as for a verified account, no new account.
        assertConflict(() -> googleSignIn.signIn(google.idToken("sub-other", ANA), details(ADULT)), "ACCOUNT_EXISTS");
        assertThat(count("account")).isOne();
    }

    private UUID idOf(String email) {
        return jdbc.sql("select id from account where email = ?")
                .param(email)
                .query(UUID.class)
                .single();
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
}
