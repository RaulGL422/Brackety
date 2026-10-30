package dev.rgal.brackety.auth.dto;

/** {@code reauthToken} goes in the {@code X-Reauth} header of the sensitive actions. */
public record ReauthResponse(String reauthToken, long expiresIn) {}
