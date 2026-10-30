package dev.rgal.brackety.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;

/** {@code PASSWORD} has no email nor link date; a provider has both. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record SignInMethodResponse(String method, String email, Instant linkedAt) {}
