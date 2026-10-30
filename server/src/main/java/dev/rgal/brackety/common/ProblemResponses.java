package dev.rgal.brackety.common;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

// For errors raised in servlet filters, before Spring MVC can render a ProblemDetail.
public final class ProblemResponses {

    private ProblemResponses() {}

    public static void write(HttpServletResponse response, HttpStatus status, String detail) throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter()
                .write("{\"type\":\"about:blank\",\"title\":\"%s\",\"status\":%d,\"detail\":\"%s\"}"
                        .formatted(status.getReasonPhrase(), status.value(), detail));
    }
}
