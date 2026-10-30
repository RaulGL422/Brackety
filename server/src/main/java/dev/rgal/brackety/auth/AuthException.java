package dev.rgal.brackety.auth;

import org.springframework.http.HttpStatus;
import org.springframework.web.ErrorResponseException;

public class AuthException extends ErrorResponseException {

    private AuthException(HttpStatus status, String detail) {
        super(status);
        setDetail(detail);
    }

    // The code lets the app pick the message to show without parsing the detail.
    private static AuthException withCode(HttpStatus status, String code, String detail) {
        var exception = new AuthException(status, detail);
        exception.getBody().setProperty("code", code);
        return exception;
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

    public static AuthException invalidSession() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Session expired. Log in again.");
    }

    public static AuthException invalidLink() {
        return new AuthException(HttpStatus.BAD_REQUEST, "This link is invalid or has expired.");
    }

    static AuthException underage() {
        return new AuthException(HttpStatus.BAD_REQUEST, "Minimum age to register is 14.");
    }

    public static AuthException googleNotConfigured() {
        return new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Google sign-in is not configured.");
    }

    static AuthException signInConflict() {
        return new AuthException(HttpStatus.CONFLICT, "Another sign-in for this account is in progress. Try again.");
    }

    public static AuthException googleSignInFailed() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Google sign-in failed.");
    }

    public static AuthException accountExists() {
        return withCode(
                HttpStatus.CONFLICT,
                "ACCOUNT_EXISTS",
                "An account with this email already exists. Sign in with your usual method and link Google from"
                        + " settings.");
    }

    public static AuthException identityInUse() {
        return withCode(
                HttpStatus.CONFLICT, "IDENTITY_IN_USE", "This Google account is already linked to another account.");
    }

    public static AuthException providerAlreadyLinked() {
        return withCode(
                HttpStatus.CONFLICT, "PROVIDER_ALREADY_LINKED", "A Google account is already linked. Unlink it first.");
    }

    public static AuthException lastSignInMethod() {
        return withCode(
                HttpStatus.CONFLICT,
                "LAST_SIGN_IN_METHOD",
                "This is the only way to sign in to the account. Add another one first.");
    }
}
