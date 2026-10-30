package dev.rgal.brackety.auth.me;

import static dev.rgal.brackety.auth.account.ProfileType.CLUB;
import static dev.rgal.brackety.auth.account.ProfileType.EXTERNAL;
import static dev.rgal.brackety.auth.account.ProfileType.EXTERNAL_ENTITY;
import static dev.rgal.brackety.auth.account.ProfileType.HELPER;
import static dev.rgal.brackety.auth.account.ProfileType.STUDENT;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import dev.rgal.brackety.auth.AuthIntegrationTest;
import dev.rgal.brackety.auth.AuthService;
import dev.rgal.brackety.auth.account.ProfileType;
import dev.rgal.brackety.auth.dto.RegisterRequest;
import dev.rgal.brackety.auth.google.FakeGoogle;
import dev.rgal.brackety.auth.reauth.ReauthService;
import dev.rgal.brackety.auth.session.SessionService.Session;
import java.time.LocalDate;
import java.util.EnumSet;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

class MeControllerTest extends AuthIntegrationTest {

    private static final String ANA = "ana@example.test";

    @Autowired
    MockMvc mvc;

    @Autowired
    AuthService auth;

    @Autowired
    FakeGoogle google;

    @Test
    void showsTheAccountItsProfilesAndItsSignInMethods() throws Exception {
        var session = account(ANA, STUDENT, true);

        mvc.perform(as(session, get("/api/v1/me")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(ANA))
                .andExpect(jsonPath("$.emailVerified").value(true))
                .andExpect(jsonPath("$.birthDate").value("1990-05-20"))
                .andExpect(jsonPath("$.locale").value("es"))
                .andExpect(jsonPath("$.profiles.length()").value(1))
                .andExpect(jsonPath("$.profiles[0].type").value("STUDENT"))
                .andExpect(jsonPath("$.profiles[0].validated").value(false))
                .andExpect(jsonPath("$.signInMethods[0].method").value("PASSWORD"))
                .andExpect(jsonPath("$.deletesOn").doesNotExist());
    }

    @Test
    void changesTheLanguageToSpanishOrEnglishOnly() throws Exception {
        var session = account(ANA, STUDENT, false);

        locale(session, "en")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.locale").value("en"));
        locale(session, "fr").andExpect(status().isBadRequest());
        assertThat(count("account where locale = 'en'")).isOne();
    }

    @Test
    void everyAllowedCombinationCanBeReached() throws Exception {
        for (var pair :
                new ProfileType[][] {{STUDENT, HELPER}, {HELPER, STUDENT}, {EXTERNAL, HELPER}, {HELPER, EXTERNAL}}) {
            resetDatabaseClockAndEmails();
            var session = account(ANA, pair[0], true);

            addProfile(session, pair[1]).andExpect(status().isNoContent());

            assertThat(count("profile")).as("%s + %s", pair[0], pair[1]).isEqualTo(2);
        }
    }

    @Test
    void everyOtherCombinationIsRefused() throws Exception {
        for (var first : ProfileType.values()) {
            for (var second : ProfileType.values()) {
                if (first == second || ProfileService.isAllowed(Set.of(first, second))) {
                    continue;
                }
                resetDatabaseClockAndEmails();
                var session = account(ANA, first, true);

                addProfile(session, second)
                        .andExpect(status().isConflict())
                        .andExpect(jsonPath("$.code").value("PROFILE_COMBINATION_NOT_ALLOWED"));
                assertThat(count("profile")).as("%s + %s", first, second).isOne();
            }
        }
    }

    @Test
    void theRulesOfTheRolesDocument() {
        assertThat(ProfileService.isAllowed(Set.of(STUDENT, HELPER))).isTrue();
        assertThat(ProfileService.isAllowed(Set.of(EXTERNAL, HELPER))).isTrue();
        assertThat(ProfileService.isAllowed(Set.of(CLUB, HELPER))).isFalse();
        assertThat(ProfileService.isAllowed(Set.of(EXTERNAL_ENTITY, HELPER))).isFalse();
        assertThat(ProfileService.isAllowed(Set.of(EXTERNAL, STUDENT))).isFalse();
        assertThat(ProfileService.isAllowed(Set.of(CLUB, EXTERNAL_ENTITY))).isFalse();
        assertThat(ProfileService.isAllowed(Set.of(STUDENT, HELPER, EXTERNAL))).isFalse();
        for (var type : ProfileType.values()) {
            assertThat(ProfileService.isAllowed(EnumSet.of(type))).isTrue();
        }
    }

    @Test
    void addingAProfileNeedsAVerifiedEmail() throws Exception {
        var session = account(ANA, STUDENT, false);

        addProfile(session, HELPER).andExpect(status().isForbidden());
        assertThat(count("profile")).isOne();
    }

    @Test
    void aNewOrganizerProfileStartsUnvalidatedAndAddingItAgainChangesNothing() throws Exception {
        var session = account(ANA, CLUB, true);
        jdbc.sql("delete from profile").update();

        addProfile(session, EXTERNAL_ENTITY).andExpect(status().isNoContent());
        addProfile(session, EXTERNAL_ENTITY).andExpect(status().isNoContent());

        assertThat(count("profile where type = 'EXTERNAL_ENTITY' and not validated"))
                .isOne();
    }

    @Test
    void theLastProfileCannotBeRemoved() throws Exception {
        var session = account(ANA, STUDENT, true);
        addProfile(session, HELPER);

        mvc.perform(as(session, delete("/api/v1/me/profiles/HELPER"))).andExpect(status().isNoContent());
        mvc.perform(as(session, delete("/api/v1/me/profiles/STUDENT")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LAST_PROFILE"));
        assertThat(count("profile where type = 'STUDENT'")).isOne();
    }

    @Test
    void exportsTheAccountDataAsADownloadWithoutThePasswordHashNorTheGoogleSubject() throws Exception {
        var session = account(ANA, STUDENT, true);
        mvc.perform(as(
                        session,
                        post("/api/v1/me/identities/google")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"idToken\":\"%s\"}"
                                        .formatted(google.idToken("sub-ana", "ana.g@example.test")))))
                .andExpect(status().isNoContent());

        var body = mvc.perform(as(session, get("/api/v1/me/export"))
                        .header(ReauthService.HEADER, reauthWithPassword(mvc, session)))
                .andExpect(status().isOk())
                .andExpect(header().string(
                                "Content-Disposition", "attachment; filename=\"brackety-data-2027-03-10.json\""))
                .andExpect(jsonPath("$.exportedAt").value("2027-03-10T09:00:00Z"))
                .andExpect(jsonPath("$.account.email").value(ANA))
                .andExpect(jsonPath("$.account.hasPassword").value(true))
                .andExpect(jsonPath("$.account.birthDate").value("1990-05-20"))
                .andExpect(jsonPath("$.profiles[0].type").value("STUDENT"))
                .andExpect(jsonPath("$.identities[0].provider").value("GOOGLE"))
                .andExpect(jsonPath("$.identities[0].email").value("ana.g@example.test"))
                .andExpect(jsonPath("$.identities[0].linkedAt").value("2027-03-10T09:00:00Z"))
                .andExpect(jsonPath("$.consents.length()").value(2))
                .andReturn()
                .getResponse()
                .getContentAsString();

        assertThat(body).doesNotContain("argon2", "sub-ana", "passwordHash");
    }

    private ResultActions addProfile(Session session, ProfileType type) throws Exception {
        return mvc.perform(as(
                session,
                post("/api/v1/me/profiles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"%s\"}".formatted(type))));
    }

    private ResultActions locale(Session session, String locale) throws Exception {
        return mvc.perform(as(
                session,
                patch("/api/v1/me")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"locale\":\"%s\"}".formatted(locale))));
    }

    // Verified before logging in, so the access token already carries the email_verified claim.
    private Session account(String email, ProfileType profile, boolean verified) {
        auth.register(
                new RegisterRequest(email, PASSWORD, LocalDate.of(1990, 5, 20), profile, "2027-01", "2027-02", "es"));
        jdbc.sql("update account set email_verified = ? where email = ?")
                .param(verified)
                .param(email)
                .update();
        return auth.login(email, PASSWORD, "203.0.113.10");
    }
}
