package dev.rgal.brackety.auth;

import org.springframework.http.HttpStatus;
import org.springframework.web.ErrorResponseException;

class AuthException extends ErrorResponseException {

    private AuthException(HttpStatus status, String detail) {
        super(status);
        setDetail(detail);
    }

    static AuthException invalidCredentials() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Invalid email or password.");
    }

    // The lock id lets the user ask the superadmin to lift the lock.
    static AuthException locked(String lockId) {
        var exception = new AuthException(HttpStatus.TOO_MANY_REQUESTS, "Too many failed attempts. Try again later.");
        exception.getBody().setProperty("lockId", lockId);
        return exception;
    }

    static AuthException invalidSession() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Session expired. Log in again.");
    }

    static AuthException underage() {
        return new AuthException(HttpStatus.BAD_REQUEST, "Minimum age to register is 14.");
    }
}
