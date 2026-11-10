package dev.rgal.brackety.auth;

import java.time.LocalDate;
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

    public static AuthException invalidCredentials() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Invalid email or password.");
    }

    // The lock id lets the user ask the superadmin to lift the lock.
    static AuthException locked(String lockId) {
        var exception = new AuthException(HttpStatus.TOO_MANY_REQUESTS, "Too many failed attempts. Try again later.");
        exception.getBody().setProperty("lockId", lockId);
        return exception;
    }

    public static AuthException superadminNotConfigured() {
        return new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "The superadmin is not configured.");
    }

    public static AuthException notFound() {
        return new AuthException(HttpStatus.NOT_FOUND, "Not found.");
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

    static AuthException invalidTaxId() {
        return withCode(HttpStatus.BAD_REQUEST, "INVALID_TAX_ID", "The CIF is not valid.");
    }

    static AuthException legalVersionOutdated() {
        return withCode(
                HttpStatus.CONFLICT,
                "LEGAL_VERSION_OUTDATED",
                "The terms or the privacy policy have changed. Review and accept the current version.");
    }

    public static AuthException googleNotConfigured() {
        return new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Google sign-in is not configured.");
    }

    static AuthException signInConflict() {
        return new AuthException(HttpStatus.CONFLICT, "Another sign-in for this account is in progress. Try again.");
    }

    public static AuthException googleUnavailable() {
        return new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Google sign-in is temporarily unavailable.");
    }

    public static AuthException emailNotVerified() {
        return withCode(
                HttpStatus.FORBIDDEN,
                "EMAIL_NOT_VERIFIED",
                "Verify the email of the account first, or link the Google account that uses that email.");
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

    public static AuthException reauthRequired() {
        return withCode(HttpStatus.FORBIDDEN, "REAUTH_REQUIRED", "Confirm your password or Google account to do this.");
    }

    // 403, not 401: the session is fine, and a 401 would make the app refresh and retry.
    public static AuthException reauthFailed() {
        return withCode(HttpStatus.FORBIDDEN, "REAUTH_FAILED", "The password or Google account does not match.");
    }

    // Only once the password or Google has proved the account is theirs, so it does not reveal anything.
    static AuthException pendingDeletion(LocalDate deletesOn, String restoreToken) {
        var exception = withCode(
                HttpStatus.FORBIDDEN, "ACCOUNT_PENDING_DELETION", "This account is pending deletion. Restore it?");
        exception.getBody().setProperty("deletesOn", deletesOn.toString());
        exception.getBody().setProperty("restoreToken", restoreToken);
        return exception;
    }

    public static AuthException suspended() {
        return withCode(HttpStatus.FORBIDDEN, "ACCOUNT_SUSPENDED", "This account is suspended.");
    }

    public static AuthException ownsEvents() {
        return withCode(
                HttpStatus.CONFLICT, "OWNS_EVENTS", "This account owns events. Hand them over or delete them first.");
    }

    public static AuthException profileCombinationNotAllowed() {
        return withCode(
                HttpStatus.CONFLICT,
                "PROFILE_COMBINATION_NOT_ALLOWED",
                "This profile cannot be combined with the ones the account has.");
    }

    public static AuthException lastProfile() {
        return withCode(HttpStatus.CONFLICT, "LAST_PROFILE", "An account needs at least one profile.");
    }
}
