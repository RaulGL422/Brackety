package dev.rgal.brackety.auth.email;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthException;
import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.google.GoogleSignInService;
import dev.rgal.brackety.auth.reauth.ReauthService;
import dev.rgal.brackety.auth.session.SessionService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import dev.rgal.brackety.notifications.Email;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

class EmailChangeTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";
    private static final String NEW = "nueva.ana@example.test";
    private static final String IP = "203.0.113.10";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    SessionService sessions;

    @Autowired
    GoogleSignInService googleSignIn;

    @Autowired
    FakeGoogle google;

    @Autowired
    PasswordResetService passwordReset;

    @Test
    void theNewAddressIsProvedByItsLinkThenReplacesTheOldOne() throws Exception {
        var session = account(ANA);
        link(session);
        emails.reset();

        requestChange(session, "Nueva.Ana@Example.TEST").andExpect(status().isAccepted());
        assertThat(count("account where email = 'ana@example.test'")).isOne();
        var link = single(NEW);
        assertThat(link.subject()).isEqualTo("Confirma tu nuevo email en Brackety");
        assertThat(link.link()).contains("/confirm-email-change?token=");

        confirm(tokenIn(link)).andExpect(status().isNoContent());

        assertThat(count("account where email = 'nueva.ana@example.test' and email_verified"))
                .isOne();
        assertThat(single(ANA).subject()).isEqualTo("El email de tu cuenta de Brackety ha cambiado");
        assertThat(single(ANA).text()).contains("n***@example.test").doesNotContain(NEW);
        assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(AuthException.class);
        assertThat(auth.login(NEW, PASSWORD, IP).accessToken()).isNotBlank();
        assertThatThrownBy(() -> auth.login(ANA, PASSWORD, IP)).isInstanceOf(AuthException.class);
        // The Google identity is the sub, not the address: it still signs in to the account.
        assertThat(googleSignIn.signIn(google.idToken("sub-ana", ANA), null).session())
                .isNotNull();
        confirm(tokenIn(link)).andExpect(status().isBadRequest());
    }

    @Test
    void anAddressInUseGetsTheSameAnswerAndOnlyItsOwnerIsTold() throws Exception {
        var session = account(ANA);
        auth.register(registration(NEW));
        emails.reset();

        requestChange(session, NEW).andExpect(status().isAccepted());

        assertThat(single(NEW).subject()).isEqualTo("Alguien ha intentado usar tu email en Brackety");
        assertThat(single(NEW).link()).doesNotContain("token=");
        assertThat(emails.sentTo(ANA)).isEmpty();
        assertThat(count("account where email = 'ana@example.test'")).isOne();
    }

    @Test
    void anAddressTakenBeforeConfirmingMakesTheLinkInvalid() throws Exception {
        var session = account(ANA);
        requestChange(session, NEW);
        var token = tokenIn(single(NEW));
        auth.register(registration(NEW));

        confirm(token).andExpect(status().isBadRequest());

        assertThat(count("account where email = 'ana@example.test'")).isOne();
        assertThat(count("account where email = 'nueva.ana@example.test'")).isOne();
    }

    @Test
    void thePresentAddressIsAcceptedAndNothingIsSent() throws Exception {
        var session = account(ANA);
        emails.reset();

        requestChange(session, "Ana@Example.test").andExpect(status().isAccepted());

        assertThat(emails.sent()).isEmpty();
        assertThat(count("email_token where purpose = 'CHANGE_EMAIL'")).isZero();
    }

    @Test
    void aPasswordResetCancelsAPendingChange() throws Exception {
        var session = account(ANA);
        emails.reset();
        requestChange(session, NEW);
        var change = tokenIn(single(NEW));

        passwordReset.forgot(ANA);
        passwordReset.reset(tokenIn(single(ANA)), "a-brand-new-password");

        confirm(change).andExpect(status().isBadRequest());
        assertThat(count("account where email = 'ana@example.test'")).isOne();
    }

    @Test
    void confirmingCancelsTheLinksSentToTheOldAddress() throws Exception {
        var session = account(ANA);
        emails.reset();
        passwordReset.forgot(ANA);
        var reset = tokenIn(single(ANA));
        requestChange(session, NEW);

        confirm(tokenIn(single(NEW))).andExpect(status().isNoContent());

        assertThatThrownBy(() -> passwordReset.reset(reset, "a-brand-new-password"))
                .isInstanceOfSatisfying(
                        AuthException.class,
                        e -> assertThat(e.getBody().getDetail()).isEqualTo("This link is invalid or has expired."));
        assertThat(auth.login(NEW, PASSWORD, IP).accessToken()).isNotBlank();
    }

    @Test
    void atMostOneEmailAMinute() throws Exception {
        var session = account(ANA);
        var reauth = reauthWithPassword(mvc, session);
        emails.reset();

        requestChange(session, reauth, NEW).andExpect(status().isAccepted());
        requestChange(session, reauth, NEW).andExpect(status().isAccepted());
        assertThat(emails.sentTo(NEW)).hasSize(1);

        clock.advance(Duration.ofSeconds(60));
        requestChange(session, reauth, NEW);
        assertThat(emails.sentTo(NEW)).hasSize(2);
    }

    @Test
    void theLinkExpiresAfter24Hours() throws Exception {
        var session = account(ANA);
        requestChange(session, NEW);

        clock.advance(Duration.ofHours(24));

        confirm(tokenIn(single(NEW))).andExpect(status().isBadRequest());
        assertThat(count("account where email = 'ana@example.test'")).isOne();
    }

    private Email single(String address) {
        assertThat(emails.sentTo(address)).hasSize(1);
        return emails.sentTo(address).getFirst();
    }

    private void link(Session session) throws Exception {
        mvc.perform(as(
                        session,
                        post("/api/v1/me/identities/google")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"idToken\":\"%s\"}".formatted(google.idToken("sub-ana", ANA)))))
                .andExpect(status().isNoContent());
    }

    private ResultActions requestChange(Session session, String newEmail) throws Exception {
        return requestChange(session, reauthWithPassword(mvc, session), newEmail);
    }

    private ResultActions requestChange(Session session, String reauth, String newEmail) throws Exception {
        return mvc.perform(as(
                        session,
                        post("/api/v1/me/email")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"newEmail\":\"%s\"}".formatted(newEmail)))
                .header(ReauthService.HEADER, reauth));
    }

    private ResultActions confirm(String token) throws Exception {
        return mvc.perform(post("/api/v1/auth/email/change/confirm")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"token\":\"%s\"}".formatted(token)));
    }

    private Session account(String email) {
        auth.register(registration(email));
        jdbc.sql("update account set email_verified = true where email = ?")
                .param(email)
                .update();
        return auth.login(email, PASSWORD, IP);
    }
}
