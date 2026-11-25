package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RequestSizeFilterTest {

    private final RequestSizeFilter filter = new RequestSizeFilter();

    @Test
    void aDeclaredBodyOverTheLimitIsRefusedWithoutReadingIt() throws Exception {
        var request = post("/api/v1/events/x/settings", new byte[(int) RequestSizeFilter.DEFAULT_LIMIT + 1]);
        var chain = new MockFilterChain();
        var response = new MockHttpServletResponse();

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(413);
        assertThat(response.getContentType()).isEqualTo(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        assertThat(chain.getRequest()).isNull();
    }

    @Test
    void aBodyWithinTheLimitPasses() throws Exception {
        var chain = new MockFilterChain();
        var response = new MockHttpServletResponse();

        filter.doFilter(post("/api/v1/events/x/settings", new byte[1024]), response, chain);

        assertThat(response.getStatus()).isEqualTo(200);
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void aChunkedBodyStopsWhenItPassesTheLimit() throws Exception {
        // No Content-Length: the size is only known while reading.
        var chunked = new MockHttpServletRequest("POST", "/api/v1/events/x/settings") {
            @Override
            public long getContentLengthLong() {
                return -1;
            }
        };
        chunked.setContent(new byte[(int) RequestSizeFilter.DEFAULT_LIMIT + 1]);
        var chain = new MockFilterChain();

        filter.doFilter(chunked, new MockHttpServletResponse(), chain);

        var passed = (HttpServletRequest) chain.getRequest();
        assertThatThrownBy(() -> passed.getInputStream().readAllBytes()).isInstanceOf(IOException.class);
    }

    @Test
    void theImportsHaveTheirOwnLimits() {
        assertThat(RequestSizeFilter.limitFor("/api/v1/events/x/import/results"))
                .isEqualTo(RequestSizeFilter.RESULTS_LIMIT);
        assertThat(RequestSizeFilter.limitFor("/api/v1/events/x/offline-ops/import"))
                .isEqualTo(RequestSizeFilter.OFFLINE_OPS_LIMIT);
        assertThat(RequestSizeFilter.limitFor("/api/v1/auth/login")).isEqualTo(RequestSizeFilter.DEFAULT_LIMIT);
    }

    @Test
    void multipartKeepsTheMultipartLimits() throws Exception {
        var request = post("/api/v1/events/x/rulebook", new byte[(int) RequestSizeFilter.DEFAULT_LIMIT + 1]);
        request.setContentType("multipart/form-data; boundary=x");
        var chain = new MockFilterChain();

        filter.doFilter(request, new MockHttpServletResponse(), chain);

        assertThat(chain.getRequest()).isNotNull();
    }

    private static MockHttpServletRequest post(String path, byte[] body) {
        var request = new MockHttpServletRequest("POST", path);
        request.setContentType(MediaType.APPLICATION_JSON_VALUE);
        request.setContent(body);
        return request;
    }
}
