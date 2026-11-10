package dev.rgal.brackety.participant;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import dev.rgal.brackety.event.EventApiTest;
import org.junit.jupiter.api.Test;

// The demo event is today (AuthTestConfig.START, 2027-03-10), so birth dates below set the age.
class ParticipantControllerTest extends EventApiTest {

    private static final String ADULT = participant("Ana", "Ruiz Gil", "1990-05-20", 165, false);

    @Test
    void clubRegistersAParticipantInTheCategoryOfTheirAge() throws Exception {
        call(post(participants()).content(participant("Leo", "Gómez", "2020-01-15", 112, true)), "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.age").value(7))
                .andExpect(jsonPath("$.categoryName").value("7-8"));
        call(post(participants()).content(ADULT), "club1")
                .andExpect(jsonPath("$.categoryName").value("26+"));

        call(get(participants()), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].firstName").value("Ana"));
    }

    @Test
    void aMinorNeedsTheGuardianConsent() throws Exception {
        call(post(participants()).content(participant("Leo", "Gómez", "2015-01-15", 140, false)), "club1")
                .andExpect(status().isBadRequest());
        call(post(participants()).content(participant("Leo", "Gómez", "2015-01-15", null, true)), "club1")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.heightCm").doesNotExist());
    }

    @Test
    void clubEditsAndDeletes() throws Exception {
        var id = create();

        call(put(participants() + "/" + id).content(participant("Ana", "Ruiz", "1990-05-20", 170, false)), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lastName").value("Ruiz"))
                .andExpect(jsonPath("$.heightCm").value(170));
        call(delete(participants() + "/" + id), "club1").andExpect(status().isNoContent());
        call(get(participants()), "club1").andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void onlyTheClubReadsAndWrites() throws Exception {
        var id = create();

        // Birth dates and guardian consent: the helper's grouping screens read only their category's list.
        call(get(participants()), "ayudante1").andExpect(status().isForbidden());
        call(post(participants()).content(ADULT), "ayudante1").andExpect(status().isForbidden());
        call(delete(participants() + "/" + id), "ayudante1").andExpect(status().isForbidden());
        call(get(participants()), "arbitro1").andExpect(status().isForbidden());
        call(get(participants()), outsider(), PASSWORD).andExpect(status().isNotFound());
    }

    private String create() throws Exception {
        var body = call(post(participants()).content(ADULT), "club1")
                .andReturn()
                .getResponse()
                .getContentAsString();
        return JsonPath.read(body, "$.id");
    }

    private String participants() {
        return "/api/v1/events/" + eventId + "/participants";
    }

    private static String participant(String first, String last, String birthDate, Integer height, boolean consent) {
        return """
                {"firstName":"%s","lastName":"%s","birthDate":"%s","heightCm":%s,"guardianConsent":%s}""".formatted(first, last, birthDate, height, consent);
    }
}
