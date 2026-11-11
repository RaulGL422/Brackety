package dev.rgal.brackety.event;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;

class OrganizationControllerTest extends EventApiTest {

    @Test
    void theDemoEventListsItsOrganizationsInTheSettings() throws Exception {
        call(get(settings()), "club1")
                .andExpect(jsonPath("$.organizations", hasSize(2)))
                .andExpect(jsonPath("$.organizations[0].name").value("Club Demo Yoseikan"))
                .andExpect(jsonPath("$.attendancePoints").value(10))
                .andExpect(jsonPath("$.phaseNumber").value(1))
                .andExpect(jsonPath("$.discipline").value("TAMBO"));
    }

    @Test
    void theClubAddsRenamesAndRemovesOrganizations() throws Exception {
        var body = call(put(organizations()).content("""
                        {"organizations":[{"id":null,"name":"Club Norte","shortName":"Norte"},
                                          {"id":null,"name":"Club Sur","shortName":" "}]}"""), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[1].shortName").doesNotExist())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String norte = JsonPath.read(body, "$[0].id");

        call(put(organizations()).content("""
                        {"organizations":[{"id":"%s","name":"Club Norte Sevilla","shortName":"Norte"}]}""".formatted(norte)), "club1")
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("Club Norte Sevilla"));
    }

    @Test
    void aParticipantBelongsToAnOrganizationThatCannotGoWhileInUse() throws Exception {
        var body = call(put(organizations()).content("""
                        {"organizations":[{"id":null,"name":"Club Norte","shortName":null}]}"""), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString();
        String norte = JsonPath.read(body, "$[0].id");

        call(post(participants()).content(participant(norte)), "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.organizationId").value(norte))
                .andExpect(jsonPath("$.organizationName").value("Club Norte"))
                .andExpect(jsonPath("$.personId").isNotEmpty());
        call(put(organizations()).content("{\"organizations\":[]}"), "club1").andExpect(status().isConflict());
    }

    @Test
    void anOrganizationOfAnotherEventOrRepeatedIsRefused() throws Exception {
        call(
                        post(participants())
                                .content(participant(java.util.UUID.randomUUID().toString())),
                        "club1")
                .andExpect(status().isBadRequest());
        call(put(organizations()).content("""
                        {"organizations":[{"id":null,"name":"Club"},{"id":null,"name":"club"}]}"""), "club1").andExpect(status().isBadRequest());
        call(put(organizations()).content("{\"organizations\":[]}"), "ayudante1")
                .andExpect(status().isForbidden());
    }

    private static String participant(String organizationId) {
        return """
                {"firstName":"Ana","lastName":"Ruiz","birthDate":"1990-05-20","heightCm":165,
                 "guardianConsent":false,"categoryId":null,"organizationId":"%s"}""".formatted(organizationId);
    }

    private String settings() {
        return "/api/v1/events/" + eventId + "/settings";
    }

    private String organizations() {
        return "/api/v1/events/" + eventId + "/organizations";
    }

    private String participants() {
        return "/api/v1/events/" + eventId + "/participants";
    }
}
