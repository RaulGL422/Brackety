package dev.rgal.brackety.event;

import org.springframework.http.HttpStatus;
import org.springframework.web.ErrorResponseException;

public class EventException extends ErrorResponseException {

    private EventException(HttpStatus status, String detail) {
        super(status);
        setDetail(detail);
    }

    // Also for events the caller has no role in, so their existence is not revealed.
    public static EventException notFound() {
        return new EventException(HttpStatus.NOT_FOUND, "Not found.");
    }

    public static EventException forbidden() {
        return new EventException(HttpStatus.FORBIDDEN, "Not allowed.");
    }

    public static EventException invalid(String detail) {
        return new EventException(HttpStatus.BAD_REQUEST, detail);
    }

    public static EventException conflict(String detail) {
        return new EventException(HttpStatus.CONFLICT, detail);
    }
}
