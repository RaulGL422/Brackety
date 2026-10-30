package dev.rgal.brackety.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Either a session ({@code SIGNED_IN}) or {@code REGISTRATION_REQUIRED} with the Google email, so the app asks for
 * the registration details and calls again with the same token. {@code refreshToken} is null for web clients.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record GoogleSignInResponse(
        Status status,
        String email,
        String accessToken,
        Long expiresIn,
        String refreshToken,
        Boolean emailVerified,
        Boolean replacedUnverifiedAccount) {

    public enum Status {
        SIGNED_IN,
        REGISTRATION_REQUIRED
    }

    public static GoogleSignInResponse registrationRequired(String email) {
        return new GoogleSignInResponse(Status.REGISTRATION_REQUIRED, email, null, null, null, null, null);
    }

    public static GoogleSignInResponse signedIn(TokenResponse tokens, boolean replacedUnverifiedAccount) {
        return new GoogleSignInResponse(
                Status.SIGNED_IN,
                null,
                tokens.accessToken(),
                tokens.expiresIn(),
                tokens.refreshToken(),
                tokens.emailVerified(),
                replacedUnverifiedAccount);
    }
}
