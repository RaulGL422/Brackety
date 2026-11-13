package dev.rgal.brackety.event;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMultipartHttpServletRequestBuilder;

class RulebookControllerTest extends EventApiTest {

    private static final byte[] PDF = "%PDF-1.7\nreglamento tambo".getBytes(StandardCharsets.US_ASCII);

    @Test
    void theClubUploadsItAndEveryRoleReadsIt() throws Exception {
        call(get(url() + "/info"), "arbitro1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileName").doesNotExist());
        call(get(url()), "arbitro1").andExpect(status().isNotFound());

        send(upload("Reglamento Fase 1.pdf", PDF), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileName").value("Reglamento Fase 1.pdf"))
                .andExpect(jsonPath("$.sizeBytes").value(PDF.length));

        for (var user : new String[] {"arbitro1", "ayudante1", "club1"}) {
            call(get(url()), user)
                    .andExpect(status().isOk())
                    .andExpect(content().contentType(MediaType.APPLICATION_PDF))
                    .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.startsWith("inline")))
                    .andExpect(content().bytes(PDF));
        }

        // A new one replaces it.
        var other = "%PDF-1.4 otro".getBytes(StandardCharsets.US_ASCII);
        send(upload("v2.pdf", other), "club1").andExpect(status().isOk());
        call(get(url()), "arbitro1").andExpect(content().bytes(other));

        call(delete(url()), "club1").andExpect(status().isNoContent());
        call(get(url()), "arbitro1").andExpect(status().isNotFound());
    }

    @Test
    void onlyAPdfFromTheClub() throws Exception {
        send(upload("notas.pdf", "hola".getBytes(StandardCharsets.UTF_8)), "club1")
                .andExpect(status().isBadRequest());
        send(upload("r.pdf", PDF), "arbitro1").andExpect(status().isForbidden());
        send(upload("r.pdf", PDF), "ayudante1").andExpect(status().isForbidden());
        call(delete(url()), "arbitro1").andExpect(status().isForbidden());
        call(get(url()), outsider(), PASSWORD).andExpect(status().isNotFound());
    }

    @Test
    void theFileNameLosesPathsAndControlCharacters() throws Exception {
        send(upload("../../etc/re\nglas.pdf", PDF), "club1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileName").value("....etcreglas.pdf"));
    }

    private MockMultipartHttpServletRequestBuilder upload(String name, byte[] bytes) {
        var builder = multipart(HttpMethod.PUT, url());
        builder.file(new MockMultipartFile("file", name, "application/pdf", bytes));
        return builder;
    }

    private ResultActions send(MockMultipartHttpServletRequestBuilder request, String user) throws Exception {
        var token = auth.login(user, user, "127.0.0.1").accessToken();
        return mvc.perform(request.header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private String url() {
        return "/api/v1/events/" + eventId + "/rulebook";
    }
}
