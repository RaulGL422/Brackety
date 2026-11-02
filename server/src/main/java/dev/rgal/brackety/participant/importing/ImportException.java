package dev.rgal.brackety.participant.importing;

import org.springframework.http.HttpStatus;
import org.springframework.web.ErrorResponseException;

class ImportException extends ErrorResponseException {

    private ImportException(HttpStatus status, String detail) {
        super(status);
        setDetail(detail);
    }

    /** No Anthropic key on this server. */
    static ImportException unavailable() {
        return new ImportException(HttpStatus.SERVICE_UNAVAILABLE, "Reading lists is not set up on this server.");
    }

    static ImportException tooManyReads() {
        return new ImportException(HttpStatus.TOO_MANY_REQUESTS, "Too many lists read in the last hour.");
    }

    /** Claude failed or the file is not readable; nothing was kept. */
    static ImportException unreadable() {
        return new ImportException(HttpStatus.BAD_GATEWAY, "The list could not be read.");
    }
}
