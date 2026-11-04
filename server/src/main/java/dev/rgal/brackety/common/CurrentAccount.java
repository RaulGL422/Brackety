package dev.rgal.brackety.common;

import java.util.UUID;
import org.springframework.security.oauth2.jwt.Jwt;

public final class CurrentAccount {

    private CurrentAccount() {}

    // The access token's subject is the account id (SessionService).
    public static UUID id(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
