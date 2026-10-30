package dev.rgal.brackety.demo;

import static org.assertj.core.api.Assertions.assertThat;

import dev.rgal.brackety.event.EventApiTest;
import org.junit.jupiter.api.Test;

class DemoSetupTest extends EventApiTest {

    @Test
    void createsVerifiedAccountsWhosePasswordIsTheUsername() {
        assertThat(count("account")).isEqualTo(8);
        assertThat(count("mat")).isEqualTo(5);
        assertThat(auth.login("arbitro5", "arbitro5", "127.0.0.1").emailVerified())
                .isTrue();
    }

    @Test
    void secondRunChangesNothing() {
        assertThat(demo.seed()).isNull();
        assertThat(count("account")).isEqualTo(8);
        assertThat(count("event")).isOne();
    }
}
