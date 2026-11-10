package dev.rgal.brackety.common;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.test.context.TestPropertySource;

// As start-event.ps1 runs it: the phones of the hotspot are on a private network, so none of them is a proxy.
@TestPropertySource(properties = "server.forward-headers-strategy=none")
class ForwardedForIgnoredTest extends ForwardedForTest {

    @Test
    void aForwardedForHeaderDoesNotChangeTheClientIp() throws Exception {
        assertThat(signInsFromSpoofedIps()).contains(429);
        assertThat(lockoutIps()).containsOnly("127.0.0.1");
    }
}
