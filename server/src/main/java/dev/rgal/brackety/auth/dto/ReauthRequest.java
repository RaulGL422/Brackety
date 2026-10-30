package dev.rgal.brackety.auth.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Size;

/** Exactly one of them: the password or a fresh Google ID token. */
public record ReauthRequest(
        @Size(max = 128) String password, @Size(max = 4096) String googleIdToken) {

    @AssertTrue(message = "Send either password or googleIdToken.")
    boolean isOneMethod() {
        return (password == null) != (googleIdToken == null);
    }

    @Override
    public String toString() {
        return "ReauthRequest[]";
    }
}
