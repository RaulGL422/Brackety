package dev.rgal.brackety.local;

import dev.rgal.brackety.auth.admin.CloudflareAccess;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

// No Cloudflare Access in front of the local API, so the superadmin API skips that check here. The switch is a
// property of application-local.properties read only by this class, which lives in test sources: production has
// neither the class nor any setting that turns the check off.
@TestConfiguration(proxyBeanMethods = false)
class LocalAdminConfig {

    static final String SKIP_ACCESS = "brackety.local.skip-cloudflare-access";

    @Bean
    @Primary
    @ConditionalOnProperty(name = SKIP_ACCESS, havingValue = "true")
    CloudflareAccess localCloudflareAccess() {
        return CloudflareAccess.notEnforced();
    }
}
