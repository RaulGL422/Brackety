package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

// The default (Pi behind cloudflared and nginx): a trusted proxy's X-Forwarded-For is the client IP.
class ForwardedForBehindProxyTest extends ForwardedForTest {

    @Test
    void aTrustedProxysForwardedForIsTheClientIp() throws Exception {
        assertThat(signInsFromSpoofedIps()).doesNotContain(429);
        assertThat(lockoutIps()).hasSize(5).allMatch(ip -> ip.startsWith("203.0.113."));
    }
}
